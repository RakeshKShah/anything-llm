import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAgentFlowBaseScenario,
  mockAgentPluginToggleScenario,
} from "../../helpers/mock-api.js";

test("User can toggle an agent’s activation state", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_toggle_activation",
    testTitle: "User can toggle an agent’s activation state",
  });

  await recorder.step("Register base system and toggle mocks", async () => {
    await setupAgentFlowBaseScenario(page);
    await mockAgentPluginToggleScenario(page, {
      hubId: "agent-123",
      status: 200,
      responseBody: { success: true, active: true },
    });
  });

  await recorder.step("Open the application", async () => {
    await page.goto("/");
    await expect(page.locator("#root")).toBeAttached();
  });

  await recorder.step("Invoke the existing frontend toggle model method", async () => {
    const result = await page.evaluate(async () => {
      const mod = await import("/src/models/experimental/agentPlugins.js");
      return await mod.default.toggleFeature("agent-123", true);
    });

    expect(result).toBe(true);
  });

  await recorder.step("Assert toggle request body", async () => {
    const captured = await page.evaluate(() => window.__agentPluginLastToggleRequestBody);
    expect(captured).toEqual({ active: true });
  });

  await recorder.step("Assert toggle response body", async () => {
    const response = await page.evaluate(() => window.__agentPluginLastToggleResponse);
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ success: true, active: true });
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_toggle_activation");
  await recorder.save(testInfo);
});
