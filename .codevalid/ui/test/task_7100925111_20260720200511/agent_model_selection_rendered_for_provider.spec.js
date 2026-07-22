import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentModelSelectionScenario } from "../../helpers/mock-api.js";

test("Agent model selection dropdown renders available LLM models for selected provider", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_model_selection_rendered_for_provider",
    testTitle: "Agent model selection dropdown renders available LLM models for selected provider",
  });

  await recorder.step("Register API mocks for provider model loading", async () => {
    await setupAgentModelSelectionScenario(page, {
      provider: "openai",
      models: [
        { id: "gpt-4", name: "gpt-4" },
        { id: "gpt-4o", name: "gpt-4o" },
        { id: "gpt-4.1", name: "gpt-4.1" }
      ],
    });
  });

  await recorder.step("Navigate to the agent configuration page", async () => {
    await page.goto("/workspace/test-workspace/settings/agent-config");
  });

  await recorder.step("Open the provider chooser", async () => {
    await expect(page.getByRole("button", { name: /System Default/i })).toBeVisible();
    await page.getByRole("button", { name: /System Default/i }).click();
    await expect(page.locator('[name="llm-search"]')).toBeVisible();
  });

  await recorder.step("Search for and select the OpenAI provider", async () => {
    await page.locator('[name="llm-search"]').fill("OpenAI");
    await page.getByText("OpenAI", { exact: true }).click();
  });

  await recorder.step("Wait for the agent model selector to render", async () => {
    await expect(page.locator('[name="agentProvider"]')).toHaveValue("openai");
    await expect(page.locator('[name="agentModel"]')).toBeVisible();
  });

  await recorder.step("Assert available model options are displayed and selectable", async () => {
    const modelSelect = page.locator('[name="agentModel"]');
    await expect(modelSelect).toContainText("gpt-4");
    await expect(modelSelect).toContainText("gpt-4o");
    await expect(modelSelect).toContainText("gpt-4.1");

    await modelSelect.selectOption("gpt-4");
    await expect(modelSelect).toHaveValue("gpt-4");
  });

  await recorder.step("Assert no load error is shown", async () => {
    await expect(page.getByText(/No models available for this provider\./i)).toHaveCount(0);
    await expect(page.getByText(/error/i)).toHaveCount(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_model_selection_rendered_for_provider");
  await recorder.save(testInfo);
});
