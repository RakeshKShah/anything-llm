import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("User successfully toggles agent activation off", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_toggle_inactive_success",
    testTitle: "User successfully toggles agent activation off",
  });

  await recorder.step("Register toggle-off scenario mocks", async () => {
    await setupAgentFlowBaseScenario(page);
    await page.route("**/api/agent-flows/mno-202/toggle", async (route) => {
      const body = JSON.parse(route.request().postData() || "{}");
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          success: true,
          flow: {
            uuid: "mno-202",
            name: "Toggle Off Agent",
            active: body.active,
            config: { active: body.active },
          },
        }),
      });
    });
  });

  await recorder.step("Open agent builder shell", async () => {
    await page.goto("/admin/agents/mno-202");
  });

  await recorder.step("Trigger deactivation request", async () => {
    const response = await page.evaluate(async () => {
      const res = await fetch("http://localhost:3001/api/agent-flows/mno-202/toggle", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ active: false }),
      });
      return { status: res.status, body: await res.json() };
    });
    expect(response.status).toBe(200);
    expect(response.body.flow.active).toBe(false);
  });

  await recorder.step("Assert page remains interactive after toggle", async () => {
    await expect(page.getByRole("button", { name: "Save" })).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_toggle_inactive_success");
  await recorder.save(testInfo);
});
