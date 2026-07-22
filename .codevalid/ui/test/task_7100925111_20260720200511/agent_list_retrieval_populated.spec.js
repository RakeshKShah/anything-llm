import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("Agent list displays all created agents", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_list_retrieval_populated",
    testTitle: "Agent list displays all created agents",
  });

  const flows = [
    { uuid: "a-1", name: "Data Summarizer", config: { active: true, steps: [{ type: "web", config: {} }] } },
    { uuid: "a-2", name: "Email Automator", config: { active: false, steps: [{ type: "email", config: {} }] } },
    { uuid: "a-3", name: "Calendar Assistant", config: { active: true, steps: [{ type: "calendar", config: {} }] } },
  ];

  await recorder.step("Register populated list mocks", async () => {
    await setupAgentFlowBaseScenario(page);
    await page.route("**/api/agent-flows/list**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({ success: true, flows }),
      });
    });
  });

  await recorder.step("Open agent management page", async () => {
    await page.goto("/admin/agents");
  });

  await recorder.step("Open flow dropdown", async () => {
    await page.getByText("Untitled Flow").click();
  });

  await recorder.step("Assert all saved flows are visible in server order", async () => {
    const flowButtons = page.locator('button').filter({ hasText: /Data Summarizer|Email Automator|Calendar Assistant/ });
    await expect(flowButtons).toHaveCount(3);
    await expect(flowButtons.nth(0)).toContainText("Data Summarizer");
    await expect(flowButtons.nth(1)).toContainText("Email Automator");
    await expect(flowButtons.nth(2)).toContainText("Calendar Assistant");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_list_retrieval_populated");
  await recorder.save(testInfo);
});
