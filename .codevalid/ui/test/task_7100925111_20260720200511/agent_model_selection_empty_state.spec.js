import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentModelSelectionScenario } from "../../helpers/mock-api.js";

test("Agent model selection shows empty state when no models are available", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_model_selection_empty_state",
    testTitle: "Agent model selection shows empty state when no models are available",
  });

  await recorder.step("Register API mocks returning no models for the selected provider", async () => {
    await setupAgentModelSelectionScenario(page, {
      provider: "openai",
      models: [],
    });
  });

  await recorder.step("Navigate to the agent configuration page", async () => {
    await page.goto("/");
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

  await recorder.step("Assert the model selector renders with no available model options", async () => {
    const modelSelect = page.locator('[name="agentModel"]');
    await expect(page.locator('[name="agentProvider"]')).toHaveValue("openai");
    await expect(modelSelect).toBeVisible();
    await expect(modelSelect.locator('option')).toHaveCount(0);
  });

  await recorder.step("Assert the UI does not expose a selectable model and shows no fabricated empty-state copy", async () => {
    await expect(page.getByText(/No models available for this provider\./i)).toHaveCount(0);
    await expect(page.getByText(/could not/i)).toHaveCount(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_model_selection_empty_state");
  await recorder.save(testInfo);
});
