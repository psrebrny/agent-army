"""Offline regression tests. The loopback API is scripted, never an advisor evaluation."""
import contextlib
import copy
import datetime
import email.message
import http.server
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock
import urllib.error

REPO = Path(__file__).resolve().parents[1]
HARNESS = REPO / ".claude/skills/advisor-eval"
sys.path.insert(0, str(HARNESS))
import api_backend as api

spec = importlib.util.spec_from_file_location("advisor_eval", HARNESS / "run.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


def completion(content="done", calls=None, finish="stop"):
    message = {"role": "assistant", "content": content}
    if calls:
        message["tool_calls"] = calls
    return {"choices": [{"message": message, "finish_reason": finish}]}


def tool(name="write_file", arguments=None):
    return {"id": "call-1", "type": "function", "function": {
        "name": name, "arguments": json.dumps(arguments or {"path": "state.md", "content": "saved"})}}


def judged(bid, score=2):
    scores = {key: score for key in runner.JUDGE_CRITERIA}
    scores["false_facts"] = 2
    return {"id": bid, "scores": scores, "false_fact_count": 0, "false_facts": [],
            "repeated_questions": 0, "oracle_hits": [], "oracle_violations": [], "note": "scripted"}


class ToolTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="advisor-tools-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.tools = api.ScratchTools(self.root)

    def call(self, name, **args):
        return json.loads(self.tools.call(name, json.dumps(args)))

    def test_file_roundtrip_and_exact_edit(self):
        self.assertIn("result", self.call("write_file", path="notes/state.md", content="alpha\nbeta"))
        self.assertEqual(self.call("read_file", path="notes/state.md")["result"]["text"], "alpha\nbeta")
        self.assertIn("result", self.call("edit_file", path="notes/state.md",
                                         old_text="beta", new_text="gamma"))
        self.assertEqual(self.call("grep", pattern="gamma")["result"]["matches"][0]["line"], 2)
        self.assertEqual(self.call("list_files")["result"]["files"], ["notes/state.md"])
        self.assertIn("error", self.call("edit_file", path="notes/state.md",
                                        old_text="missing", new_text="x"))
        self.assertEqual(self.call("read_file", path="notes/state.md", offset=6, limit=2)["result"],
                         {"text": "ga", "next_offset": 8})

    def test_all_tools_reject_escape_and_protected_paths(self):
        for path in ("../outside", "a/../../outside", "/etc/passwd", ".git/config", ".claude/x",
                     "notes/.git/config", "notes/.claude/x", r"..\outside", "C:/outside", "\0x"):
            for name, extra in (("read_file", {}), ("write_file", {"content": "x"}),
                                ("edit_file", {"old_text": "x", "new_text": "y"}),
                                ("list_files", {}), ("grep", {"pattern": "x"})):
                with self.subTest(path=path, tool=name):
                    self.assertIn("error", self.call(name, path=path, **extra))

    def test_symlinks_hardlinks_and_special_files_are_rejected(self):
        outside = self.root / "outside"
        outside.mkdir()
        (outside / "secret").write_text("private")
        (self.root / "link").symlink_to(outside, target_is_directory=True)
        (self.root / "dangling").symlink_to(self.root / "missing")
        os.link(outside / "secret", self.root / "hardlink")
        os.mkfifo(self.root / "fifo")
        for path in ("link/secret", "dangling", "hardlink", "fifo"):
            self.assertIn("error", self.call("read_file", path=path))
            self.assertIn("error", self.call("write_file", path=path, content="replace"))
        self.assertEqual((outside / "secret").read_text(), "private")
        self.assertNotIn("link/secret", self.call("list_files")["result"]["files"])

    def test_scan_hides_protected_files_and_snapshot_hides_links(self):
        for directory in (".git", ".claude", "nested/.claude"):
            target = self.root / directory / "hidden"
            target.parent.mkdir(parents=True)
            target.write_text("private")
        (self.root / "visible").write_text("private")
        (self.root / "alias").symlink_to(self.root / "visible")
        self.assertEqual(self.call("list_files")["result"]["files"], ["visible"])
        self.assertEqual(len(self.call("grep", pattern="private")["result"]["matches"]), 1)
        self.assertEqual(set(runner.snapshot(self.root)), {"visible"})

    def test_invalid_arguments_and_size_limits(self):
        for name, arguments in (("shell", "{}"), ("read_file", "[]"), ("read_file", "{"),
                                ("write_file", '{"path": "x", "content": 1}'),
                                ("read_file", '{"path":"x","extra":"y"}')):
            self.assertIn("error", json.loads(self.tools.call(name, arguments)))
        self.assertIn("error", self.call("write_file", path="large", content="a" * (api.MAX_FILE_BYTES + 1)))
        self.assertFalse((self.root / "large").exists())
        self.call("write_file", path="x", content="xx")
        self.assertIn("error", self.call("read_file", path="x", offset=True))
        self.assertIn("error", self.call("edit_file", path="x", old_text="x", new_text="z"))
        self.assertIn("error", self.call("grep", pattern=""))


class EnvFileTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="advisor-env-")
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / ".env"

    def test_loads_only_aux_settings_without_shell_evaluation(self):
        self.path.write_text("# local configuration\nAUX_BASE_URL=https://example.invalid/v1\n"
                             "export AUX_API_KEY='test-value'\nAUX_MODEL=pinned-in-code-not-here\n"
                             "UNRELATED=not-for-the-runner\n")
        result = api.load_api_environment(self.path, {})
        self.assertEqual(result, {"AUX_BASE_URL": "https://example.invalid/v1",
                                  "AUX_API_KEY": "test-value"})
        self.path.write_text("AUX_API_KEY=$(touch should-not-exist)\n")
        self.assertEqual(api.load_api_environment(self.path, {})["AUX_API_KEY"],
                         "$(touch should-not-exist)")
        self.assertFalse((self.path.parent / "should-not-exist").exists())

    def test_environment_takes_precedence_and_missing_file_is_optional(self):
        self.assertEqual(api.load_api_environment(self.path, {"AUX_BASE_URL": "https://env.invalid/v1"})
                         ["AUX_BASE_URL"], "https://env.invalid/v1")
        self.path.write_text("AUX_BASE_URL=https://file.invalid/v1\nAUX_API_KEY=test-value\n")
        self.assertEqual(api.load_api_environment(self.path, {"AUX_BASE_URL": "https://env.invalid/v1"})
                         ["AUX_BASE_URL"], "https://env.invalid/v1")
        self.assertEqual(api.load_api_environment(self.path, {"AUX_API_KEY": ""})["AUX_API_KEY"], "")

    def test_malformed_file_and_symlinks_fail_without_echoing_values(self):
        for content in ("AUX_API_KEY='test-value\n", "test-value-without-equals\n",
                        "AUX_API_KEY=test-value\nAUX_API_KEY=other\n"):
            self.path.write_text(content)
            with self.subTest(content=content), self.assertRaises(api.EvalError) as raised:
                api.load_api_environment(self.path, {})
            self.assertNotIn("test-value", str(raised.exception))
        self.path.unlink()
        self.path.symlink_to(self.path.parent / "missing")
        with self.assertRaises(api.EvalError):
            api.load_api_environment(self.path, {})


class TransportTests(unittest.TestCase):
    def setUp(self):
        self.config = api.ApiConfig("https://example.invalid/v1/", "test-key", retries=2)

    def response(self, value):
        return contextlib.closing(io.BytesIO(json.dumps(value).encode()))

    def test_request_schema_and_no_key_in_payload(self):
        opener = mock.Mock()
        opener.open.return_value = self.response(completion())
        with mock.patch.object(api.urllib.request, "build_opener", return_value=opener):
            result = api.aux_chat(self.config, "pinned-model", [{"role": "user", "content": "hello"}],
                                  tools=api.FILE_TOOLS, json_object=True)
        request = opener.open.call_args.args[0]
        self.assertEqual(request.full_url, "https://example.invalid/v1/chat/completions")
        self.assertEqual(request.get_header("Authorization"), "Bearer test-key")
        payload = json.loads(request.data)
        self.assertEqual(payload["model"], "pinned-model")
        self.assertEqual(payload["response_format"], {"type": "json_object"})
        self.assertEqual(len(payload["tools"]), 5)
        self.assertNotIn("test-key", request.data.decode())
        self.assertEqual(result["total_cost_usd"], 0)

    def test_retries_429_5xx_and_retry_after(self):
        headers = email.message.Message()
        headers["Retry-After"] = "3"
        opener = mock.Mock()
        opener.open.side_effect = [
            urllib.error.HTTPError("https://example.invalid", 429, "rate", headers, None),
            urllib.error.HTTPError("https://example.invalid", 503, "busy", email.message.Message(), None),
            self.response(completion()),
        ]
        with mock.patch.object(api.urllib.request, "build_opener", return_value=opener), \
                mock.patch.object(api.time, "sleep") as sleep:
            api.aux_chat(self.config, "model", [])
        self.assertEqual(sleep.call_args_list, [mock.call(3), mock.call(2)])
        self.assertEqual(opener.open.call_count, 3)

    def test_timeout_retries_are_bounded_and_errors_hide_secrets(self):
        opener = mock.Mock()
        opener.open.side_effect = TimeoutError("test-key")
        with mock.patch.object(api.urllib.request, "build_opener", return_value=opener), \
                mock.patch.object(api.time, "sleep"), self.assertRaises(api.EvalError) as raised:
            api.aux_chat(self.config, "model", [])
        self.assertEqual(opener.open.call_count, 3)
        self.assertNotIn("test-key", str(raised.exception))

    def test_401_is_not_retried_and_redirect_is_refused(self):
        opener = mock.Mock()
        opener.open.side_effect = urllib.error.HTTPError("https://test-key@example.invalid", 401,
                                                         "test-key", email.message.Message(), None)
        with mock.patch.object(api.urllib.request, "build_opener", return_value=opener), \
                self.assertRaisesRegex(api.EvalError, "HTTP 401") as raised:
            api.aux_chat(self.config, "model", [])
        self.assertNotIn("test-key", str(raised.exception))
        self.assertEqual(opener.open.call_count, 1)
        self.assertIsNone(api.NoRedirect().redirect_request(None, None, 302, "", {}, "https://other"))

    def test_retry_after_date_and_long_quota_wait(self):
        value = datetime.datetime.fromtimestamp(1030, datetime.timezone.utc)
        with mock.patch.object(api.time, "time", return_value=1000):
            self.assertEqual(api.retry_delay(api.email.utils.format_datetime(value), 0), 30)
        self.assertEqual(api.retry_delay("not-a-date", 2), 4)
        with self.assertRaises(api.EvalError):
            api.retry_delay("121", 0)

    def test_invalid_or_truncated_completions_fail(self):
        for value in ({}, completion(finish="length"), completion(content=None),
                      completion(calls="bad")):
            opener = mock.Mock()
            opener.open.return_value = self.response(value)
            with self.subTest(value=value), \
                    mock.patch.object(api.urllib.request, "build_opener", return_value=opener), \
                    self.assertRaises(api.EvalError):
                api.aux_chat(self.config, "model", [])

    def test_config_requires_https_and_env_key(self):
        for url in ("", "http://remote.example/v1", "https://key@host/v1",
                    "https://host/v1?key=secret", "https://host/v1#secret"):
            with self.subTest(url=url), self.assertRaises(api.EvalError):
                api.ApiConfig(url, "test")
        api.ApiConfig("http://127.0.0.1:1234/v1", "test")
        self.assertNotIn("test-key", repr(self.config))
        with self.assertRaises(api.EvalError) as raised:
            api.ApiConfig("https://host/v1", "test-key\n")
        self.assertNotIn("test-key", str(raised.exception))
        with self.assertRaises(api.EvalError):
            api.ApiConfig("https://host:bad/v1", "test-key")
        with self.assertRaises(api.EvalError):
            api.ApiConfig("https://host/v1", "test-key", timeout=float("nan"))


class ProtocolTests(unittest.TestCase):
    def test_prompts_include_contract_and_references_only_for_candidate(self):
        prompt = api.actor_prompt(runner.SKILLS / "positioning-offer", runner.CONTRACT)
        for text in ("positioning-offer/SKILL.md", "product/advisor-contract.md",
                     "positioning-offer/references/page-copy.md"):
            self.assertIn(text, prompt)
            self.assertNotIn(text, api.actor_prompt())
        self.assertNotIn("Oracle: S18", prompt)
        self.assertNotIn("Simulated user: Tomek", prompt)

    def test_actor_keeps_text_before_tools_and_limits_total_calls(self):
        with tempfile.TemporaryDirectory() as root:
            tools = api.ScratchTools(root)
            responses = [
                {"message": completion("before", [tool()])["choices"][0]["message"], "num_turns": 1},
                {"message": completion("after")["choices"][0]["message"], "num_turns": 1},
            ]
            history = [{"role": "user", "content": "start"}]
            with mock.patch.object(api, "aux_chat", side_effect=responses):
                text, cost = api.actor_turn(None, "model", history, tools, 1)
            self.assertEqual(text, "before\n\nafter")
            self.assertEqual(cost["num_turns"], 2)
            self.assertEqual(history[-2]["role"], "tool")
            with mock.patch.object(api, "aux_chat", return_value={
                    "message": completion(None, [tool(), tool()])["choices"][0]["message"], "num_turns": 1}):
                with self.assertRaisesRegex(api.EvalError, "exceeded"):
                    api.actor_turn(None, "model", [], tools, 1)

    def test_resume_histories_are_fresh_and_max_turns_is_exact(self):
        histories = []

        def actor(config, model, history, tools, limit, on_tool=None):
            histories.append(copy.deepcopy(history))
            return "done", {"num_turns": 1, "total_cost_usd": 0, "duration_ms": 1}

        with tempfile.TemporaryDirectory() as root, \
                mock.patch.object(runner, "actor_turn", side_effect=actor), \
                mock.patch.object(runner, "aux_chat", return_value={"message": {
                    "role": "assistant", "content": "continue"}}), contextlib.redirect_stdout(io.StringIO()):
            first = runner.converse_api(root, "opening", "persona", "system", None,
                                         "actor", "persona", "one", max_turns=2)
            second = runner.converse_api(root, "resume", "persona", "system", None,
                                          "actor", "persona", "two", max_turns=1)
        self.assertEqual(len(first[0]), 2)
        self.assertTrue(first[2])
        self.assertTrue(second[2])
        self.assertEqual(histories[-1], [{"role": "system", "content": "system"},
                                        {"role": "user", "content": "resume"}])

    def test_parser_rejects_missing_invalid_and_contradictory_scores(self):
        self.assertEqual(runner.parse_judge(json.dumps({"bundles": [judged("a")]}), {"a": None},
                                            Path("/tmp"))["bundles"][0]["id"], "a")
        for change in ("missing", "bad-score", "bad-count", "contradiction", "duplicate"):
            entry = judged("a")
            if change == "bad-score":
                entry["scores"]["pace"] = 3
            if change == "bad-count":
                entry["false_fact_count"] = "0"
            if change == "contradiction":
                entry["false_fact_count"] = 1
            entries = [] if change == "missing" else [entry]
            if change == "duplicate":
                entries.append(entry)
            with self.subTest(change=change), self.assertRaises(api.EvalError):
                runner.parse_judge(json.dumps({"bundles": entries}), {"a": None}, Path("/tmp"))

    def test_parser_preserves_legacy_verbatim_recovery(self):
        a, b = json.dumps(judged("a")), json.dumps(judged("b"))
        text = '{"bundles":[' + a + "]}" + "," + b + "]}"
        with contextlib.redirect_stdout(io.StringIO()):
            result = runner.parse_judge(text, {"a": None, "b": None}, Path("/tmp"))
        self.assertEqual([b["id"] for b in result["bundles"]], ["a", "b"])

    def test_defaults_cover_every_product_skill_once(self):
        skills = {p.parent.name for p in runner.SKILLS.glob("*/SKILL.md")
                  if "advisor-contract.md" in p.read_text()}
        self.assertEqual(set(runner.DEFAULT_SCENARIOS), skills)
        self.assertEqual(len(runner.DEFAULT_SCENARIOS), 16)

    def test_claude_role_models_and_persona_args_are_used(self):
        calls = []

        def claude(args, cwd, prompt, whole_turn=False):
            calls.append((args, prompt, whole_turn))
            if whole_turn:
                return {"turn_text": "done", "num_turns": 1, "total_cost_usd": 0.1, "duration_ms": 1}
            if "--system-prompt" in args:
                return {"result": "ok, thanks"}
            bids = sorted(p.name for p in (cwd / "bundles").iterdir())
            return {"result": json.dumps({"bundles": [judged(bid) for bid in bids]})}

        # K-only avoids a comparative verdict; it still exercises both sessions/personas and judge.
        with mock.patch.object(sys, "argv", ["run.py", "positioning-offer", "--scenario", "S18",
                                            "--backend", "claude", "--arms", "K", "--actor-model", "sonnet",
                                            "--persona-model", "persona-model", "--judge-model",
                                            "judge-model", "--no-ledger"]), \
                mock.patch.object(runner.shutil, "which", return_value="/unused/claude"), \
                mock.patch.object(runner, "claude", side_effect=claude), \
                contextlib.redirect_stdout(io.StringIO()):
            runner.main()
        self.assertEqual([args[1] for args, _, _ in calls],
                         ["sonnet", "persona-model", "sonnet", "persona-model", "judge-model"])
        self.assertEqual(runner.cost_score({"num_turns": 1, "total_cost_usd": .4, "duration_ms": 1},
                                           "sonnet"), 1)


class ScriptedHandler(http.server.BaseHTTPRequestHandler):
    """Only protocol mechanics; scores here are fabricated test data, never ledger evidence."""
    def log_message(self, *args):
        pass

    def do_POST(self):
        payload = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        with self.server.lock:
            self.server.requests.append(copy.deepcopy(payload))
        messages = payload["messages"]
        if "tools" in payload:
            candidate = "Loaded instruction file" in messages[0]["content"]
            calls = sum(message["role"] == "tool" for message in messages)
            if not calls:
                result = completion("checking", [tool("read_file", {"path": "state.md"})], "tool_calls")
            elif calls == 1:
                result = completion(None, [tool()], "tool_calls")
            else:
                result = completion("candidate-result: done" if candidate else "control-result: done")
            with self.server.lock:
                self.server.active += 1
                self.server.max_active = max(self.server.max_active, self.server.active)
            time.sleep(.01)
            with self.server.lock:
                self.server.active -= 1
        elif "Score eight criteria" in messages[0]["content"]:
            data = json.loads(messages[1]["content"].split("\n", 1)[1])
            entries = {}
            for file in data["files"]:
                parts = Path(file["path"]).parts
                if parts[0] == "bundles" and parts[-1] == "session-1.md":
                    entries[parts[1]] = judged(parts[1], 2 if "candidate-result" in file["content"] else 1)
            if self.server.bad_judge:
                entries = {}
            if self.server.false_fact:
                for entry in entries.values():
                    if entry["scores"]["pace"] == 2:
                        entry["false_fact_count"] = 1
                        entry["scores"]["false_facts"] = 1
            result = completion(json.dumps({"bundles": list(entries.values())}))
        else:
            result = completion("continue" if self.server.loop else "ok, thanks")
        data = json.dumps(result).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


class EndToEndTests(unittest.TestCase):
    def setUp(self):
        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), ScriptedHandler)
        self.server.requests, self.server.lock = [], threading.Lock()
        self.server.active = self.server.max_active = 0
        self.server.bad_judge = self.server.false_fact = self.server.loop = False
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.addCleanup(self.stop)

    def stop(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def run_cli(self, *args):
        env = dict(os.environ, AUX_BASE_URL=f"http://127.0.0.1:{self.server.server_port}/v1",
                   AUX_API_KEY="scripted-test-key")
        return subprocess.run([sys.executable, str(HARNESS / "run.py"), "--backend", "api",
                               "--judge-backend", "api", "--model", "scripted-model",
                               "--no-ledger", *args], env=env, text=True, capture_output=True, timeout=60)

    def test_parallel_real_http_tools_resume_judge_and_no_ledger(self):
        before = runner.LEDGER.read_bytes()
        result = self.run_cli("positioning-offer", "--scenario", "S18", "--parallel", "--judge-json",
                              "--actor-model", "actor-model", "--persona-model", "persona-model",
                              "--judge-model", "judge-model")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("| pass |", result.stdout)
        self.assertIn("backend=api; actor=actor-model; persona=persona-model; judge=api:judge-model",
                      result.stdout)
        self.assertGreaterEqual(self.server.max_active, 2)
        self.assertEqual(runner.LEDGER.read_bytes(), before)
        self.assertNotIn("scripted-test-key", result.stdout + result.stderr)
        actors = [p for p in self.server.requests if "tools" in p]
        fresh = [p for p in actors if len(p["messages"]) == 2]
        self.assertEqual(len(fresh), 4)  # N/K × new session 1/2 histories
        self.assertTrue(all(p["model"] == "actor-model" for p in actors))
        tool_results = [m["content"] for p in actors for m in p["messages"] if m["role"] == "tool"]
        self.assertTrue(any('"text": "saved"' in text for text in tool_results))
        for payload in self.server.requests:
            if payload["model"] == "persona-model":
                self.assertNotIn("tools", payload)
                self.assertNotIn("Oracle:", json.dumps(payload))
            if payload["model"] == "judge-model":
                self.assertNotIn("tools", payload)
                self.assertEqual(payload["response_format"], {"type": "json_object"})
                self.assertNotIn("harness-only", payload["messages"][0]["content"])
                self.assertIn("Oracle: S18", payload["messages"][1]["content"])

    def test_all_runs_sixteen_representatives_without_claude(self):
        result = self.run_cli("--all", "--parallel")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout.count("| pass |"), 16)
        self.assertIn("| product-metrics |", result.stdout)
        self.assertIn("| market-research |", result.stdout)
        self.assertNotIn("| S9 web |", result.stdout)
        self.assertEqual({p["model"] for p in self.server.requests}, {"scripted-model"})

    def test_bad_judge_and_safety_stop_never_record_a_score(self):
        before = runner.LEDGER.read_bytes()
        self.server.bad_judge = True
        result = self.run_cli("positioning-offer", "--scenario", "S18")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("skipped/added", result.stderr)
        self.assertNotIn("| pass |", result.stdout)
        self.server.bad_judge = False
        self.server.loop = True
        result = self.run_cli("positioning-offer", "--scenario", "S18", "--max-turns", "1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("safety stop", result.stderr)
        self.assertEqual(runner.LEDGER.read_bytes(), before)

    def test_default_judge_runs_on_claude_while_actor_and_persona_stay_on_api(self):
        fake = Path(tempfile.mkdtemp(prefix="fake-claude-"))
        self.addCleanup(shutil.rmtree, fake)
        log = fake / "calls.log"
        script = fake / "claude"
        script.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys\n"
            f"pathlib.Path({str(log)!r}).open('a').write(' '.join(sys.argv[1:4]) + chr(10))\n"
            "model = sys.argv[sys.argv.index('--model') + 1]\n"
            "bids = sorted(p.name for p in pathlib.Path('bundles').iterdir())\n"
            f"entries = [dict({json.dumps(judged('x'))}, id=b) for b in bids]\n"
            "print(json.dumps({'result': json.dumps({'bundles': entries}),"
            " 'total_cost_usd': 0.02, 'model': model}))\n")
        script.chmod(0o755)
        env = dict(os.environ, PATH=f"{fake}{os.pathsep}{os.environ['PATH']}",
                   AUX_BASE_URL=f"http://127.0.0.1:{self.server.server_port}/v1",
                   AUX_API_KEY="scripted-test-key")
        result = subprocess.run([sys.executable, str(HARNESS / "run.py"),  # default backend: api
                                 "--model", "scripted-model", "--no-ledger", "positioning-offer",
                                 "--scenario", "S18", "--arms", "K"],  # K-only: no comparative verdict
                                env=env, text=True, capture_output=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("judge=claude:sonnet", result.stdout)
        self.assertEqual(len(log.read_text().splitlines()), 1)  # one judge call, no actor/persona
        self.assertEqual({p["model"] for p in self.server.requests}, {"scripted-model"})
        self.assertFalse(any("Oracle:" in json.dumps(p) for p in self.server.requests))

    def test_all_stops_after_fix_contract(self):
        self.server.false_fact = True
        result = self.run_cli("--all")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout.count("| fix-contract |"), 1)
        self.assertNotIn("| positioning-offer |", result.stdout)

    def test_keep_going_finishes_the_batch_and_fails_with_a_summary(self):
        self.server.false_fact = True
        result = self.run_cli("--all", "--keep-going")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout.count("| fix-contract |"), 16)
        self.assertIn("16 of 16 scenario(s) failed", result.stderr)


if __name__ == "__main__":
    unittest.main()
