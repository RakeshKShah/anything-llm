import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("Agent list displays empty state when no agents exist", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_list_retrieval_empty",
    testTitle: "Agent list displays empty state when no agents exist",
  });

  await recorder.step("Register list-empty mocks", async () => {
    await setupAgentFlowBaseScenario(page);
    await page.route("**/api/agent-flows/list**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({ success: true, flows: [] }),
      });
    });
  });

  await recorder.step("Open the agent management page", async () => {
    await page.goto("/admin/agents");
  });

  await recorder.step("Assert builder shell and empty flow selection state", async () => {
    await expect(page.getByRole("button", { name: "New Flow" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Publish" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Save" })).toBeVisible();
    await expect(page.getByText("Untitled Flow")).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_list_retrieval_empty");
  await recorder.save(testInfo);
});
