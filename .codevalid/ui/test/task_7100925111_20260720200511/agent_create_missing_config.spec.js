import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("Agent creation fails when config is omitted", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_create_missing_config",
    testTitle: "Agent creation fails when config is omitted",
  });

  await recorder.step("Register base routes", async () => {
    await setupAgentFlowBaseScenario(page);
  });

  await recorder.step("Open agent builder", async () => {
    await page.goto("/admin/agents");
  });

  await recorder.step("Provide name but omit required description/config details", async () => {
    await page.locator('[name="name"]').fill("Data Summarizer");
    await page.locator('[name="description"]').fill("");
  });

  await recorder.step("Attempt to save incomplete agent", async () => {
    await page.getByRole("button", { name: "Save" }).click();
  });

  await recorder.step("Assert validation feedback is shown", async () => {
    await expect(page.locator('[name="description"]')).toBeFocused();
    await expect(page.getByText("Please provide both a name and description for your flow")).toBeVisible();
    await expect(page.getByRole("button", { name: "Save" })).toBeEnabled();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_create_missing_config");
  await recorder.save(testInfo);
});
