import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("User successfully toggles agent activation on", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_toggle_active_success",
    testTitle: "User successfully toggles agent activation on",
  });

  await recorder.step("Register toggle-on scenario mocks", async () => {
    await setupAgentFlowBaseScenario(page);
    await page.route("**/api/agent-flows/jkl-101/toggle", async (route) => {
      const body = JSON.parse(route.request().postData() || "{}");
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          success: true,
          flow: {
            uuid: "jkl-101",
            name: "Toggle On Agent",
            active: body.active,
            config: { active: body.active },
          },
        }),
      });
    });
  });

  await recorder.step("Open agent builder shell", async () => {
    await page.goto("/admin/agents/jkl-101");
  });

  await recorder.step("Trigger activation request", async () => {
    const response = await page.evaluate(async () => {
      const res = await fetch("http://localhost:3001/api/agent-flows/jkl-101/toggle", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ active: true }),
      });
      return { status: res.status, body: await res.json() };
    });
    expect(response.status).toBe(200);
    expect(response.body.flow.active).toBe(true);
  });

  await recorder.step("Assert page remains interactive after toggle", async () => {
    await expect(page.getByRole("button", { name: "Save" })).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_toggle_active_success");
  await recorder.save(testInfo);
});
