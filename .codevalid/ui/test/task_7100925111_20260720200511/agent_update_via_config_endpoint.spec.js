import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAgentFlowBaseScenario,
  mockAgentPluginConfigScenario,
} from "../../helpers/mock-api.js";

test("User updates an existing agent’s configuration via the UI", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_update_via_config_endpoint",
    testTitle: "User updates an existing agent’s configuration via the UI",
  });

  await recorder.step("Register base system and agent plugin config mocks", async () => {
    await setupAgentFlowBaseScenario(page);
    await mockAgentPluginConfigScenario(page, {
      hubId: "agent-123",
      status: 200,
      responseBody: {
        success: true,
        hubId: "agent-123",
        capabilities: ["calculator"],
      },
    });
  });

  await recorder.step("Open the application", async () => {
    await page.goto("/");
    await expect(page.locator("#root")).toBeAttached();
  });

  await recorder.step("Invoke the existing frontend agent plugin config model method", async () => {
    const result = await page.evaluate(async () => {
      const mod = await import("/src/models/experimental/agentPlugins.js");
      return await mod.default.updatePluginConfig("agent-123", {
        capabilities: ["calculator"],
      });
    });

    expect(result).toBe(true);
  });

  await recorder.step("Assert request payload captured by mock helper", async () => {
    const captured = await page.evaluate(() => window.__agentPluginLastConfigRequestBody);
    expect(captured).toEqual({ updates: { capabilities: ["calculator"] } });
  });

  await recorder.step("Assert successful backend response was observed", async () => {
    const response = await page.evaluate(() => window.__agentPluginLastConfigResponse);
    expect(response.status).toBe(200);
    expect(response.body).toEqual({
      success: true,
      hubId: "agent-123",
      capabilities: ["calculator"],
    });
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_update_via_config_endpoint");
  await recorder.save(testInfo);
});
