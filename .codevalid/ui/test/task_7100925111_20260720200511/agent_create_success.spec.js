import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("User successfully creates a new autonomous AI agent", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_create_success",
    testTitle: "User successfully creates a new autonomous AI agent",
  });

  await recorder.step("Register base and save-success mocks", async () => {
    await setupAgentFlowBaseScenario(page, {
      flowUuid: "flow-data-summarizer-001",
      flowName: "Data Summarizer",
      description: "Summarizes extracted data for users.",
    });

    await page.route("**/api/agent-flows/save**", async (route) => {
      const payload = JSON.parse(route.request().postData() || "{}");
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          success: true,
          flow: {
            uuid: "flow-data-summarizer-001",
            name: payload.name,
            config: payload.config ?? { blocks: [{ type: "data-extraction" }] },
            active: true,
          },
        }),
      });
    });

    await page.route("**/api/agent-flows/list**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          success: true,
          flows: [
            {
              uuid: "flow-data-summarizer-001",
              name: "Data Summarizer",
              config: { active: true, steps: [{ type: "data-extraction", config: {} }] },
            },
          ],
        }),
      });
    });
  });

  await recorder.step("Open the agent builder UI", async () => {
    await page.goto("/admin/agents");
  });

  await recorder.step("Populate the agent name and description fields", async () => {
    await page.locator('[name="name"]').fill("Data Summarizer");
    await page.locator('[name="description"]').fill("Summarizes extracted data for users.");
  });

  await recorder.step("Save the agent flow", async () => {
    await page.getByRole("button", { name: "Save" }).click();
  });

  await recorder.step("Assert successful save feedback", async () => {
    await expect(page.getByText("Agent flow saved successfully!")).toBeVisible();
    await expect(page.locator('[name="name"]')).toHaveValue("Data Summarizer");
    await expect(page.locator('[name="description"]')).toHaveValue("Summarizes extracted data for users.");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_create_success");
  await recorder.save(testInfo);
});
