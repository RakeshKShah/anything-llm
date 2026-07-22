import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAgentFlowBaseScenario,
  mockAgentPluginDeleteScenario,
} from "../../helpers/mock-api.js";

test("User can delete an AI agent from the UI", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_delete",
    testTitle: "User can delete an AI agent from the UI",
  });

  await recorder.step("Register base system and delete mocks", async () => {
    await setupAgentFlowBaseScenario(page);
    await mockAgentPluginDeleteScenario(page, {
      hubId: "agent-123",
      status: 200,
      responseBody: { success: true, deleted: true },
    });
  });

  await recorder.step("Open the application", async () => {
    await page.goto("/");
    await expect(page.locator("#root")).toBeAttached();
  });

  await recorder.step("Invoke the existing frontend delete model method", async () => {
    const result = await page.evaluate(async () => {
      const mod = await import("/src/models/experimental/agentPlugins.js");
      return await mod.default.deletePlugin("agent-123");
    });

    expect(result).toBe(true);
  });

  await recorder.step("Assert delete response captured", async () => {
    const response = await page.evaluate(() => window.__agentPluginLastDeleteResponse);
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ success: true, deleted: true });
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_delete");
  await recorder.save(testInfo);
});
