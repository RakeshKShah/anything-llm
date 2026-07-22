import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("Agent creation fails when name is omitted", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_create_missing_name",
    testTitle: "Agent creation fails when name is omitted",
  });

  await recorder.step("Register base routes", async () => {
    await setupAgentFlowBaseScenario(page);
  });

  await recorder.step("Open agent builder", async () => {
    await page.goto("/admin/agents");
  });

  await recorder.step("Leave name empty and provide description", async () => {
    await page.locator('[name="name"]').fill("");
    await page.locator('[name="description"]').fill("Valid config with blocks is prepared.");
  });

  await recorder.step("Attempt to save without a name", async () => {
    await page.getByRole("button", { name: "Save" }).click();
  });

  await recorder.step("Assert client-side validation prevents save", async () => {
    await expect(page.locator('[name="name"]')).toBeFocused();
    await expect(page.getByText("Please provide both a name and description for your flow")).toBeVisible();
    await expect(page.getByRole("button", { name: "Save" })).toBeEnabled();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_create_missing_name");
  await recorder.save(testInfo);
});
