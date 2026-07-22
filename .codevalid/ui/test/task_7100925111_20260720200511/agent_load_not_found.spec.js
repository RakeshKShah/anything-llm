import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("Loading a non-existent agent returns a clear error", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_load_not_found",
    testTitle: "Loading a non-existent agent returns a clear error",
  });

  await recorder.step("Register 404 load mock", async () => {
    await setupAgentFlowBaseScenario(page);
    await page.route("**/api/agent-flows/xyz-999**", async (route) => {
      if (route.request().method() !== "GET") return route.continue();
      await route.fulfill({
        status: 404,
        contentType: "application/json",
        body: JSON.stringify({ success: false, error: "Flow not found" }),
      });
    });
  });

  await recorder.step("Open stale flow URL", async () => {
    await page.goto("/admin/agents/xyz-999");
  });

  await recorder.step("Assert user sees failure message", async () => {
    await expect(page.getByText("Failed to load flow")).toBeVisible();
    await expect(page.locator('[name="name"]')).toHaveValue("");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_load_not_found");
  await recorder.save(testInfo);
});
