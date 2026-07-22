import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("User successfully loads a specific agent by UUID", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_load_success",
    testTitle: "User successfully loads a specific agent by UUID",
  });

  await recorder.step("Register list and load mocks", async () => {
    await setupAgentFlowBaseScenario(page);

    await page.route("**/api/agent-flows/list**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          success: true,
          flows: [{ uuid: "abc-123", name: "Data Summarizer", config: { active: true, steps: [{ type: "web-scrape", config: {} }] } }],
        }),
      });
    });

    await page.route("**/api/agent-flows/abc-123**", async (route) => {
      if (route.request().method() !== "GET") return route.continue();
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          success: true,
          flow: {
            uuid: "abc-123",
            name: "Data Summarizer",
            config: {
              name: "Data Summarizer",
              description: "Loads a specific flow for editing.",
              active: true,
              steps: [{ type: "web-scrape", config: { url: "https://example.com" } }],
            },
          },
        }),
      });
    });
  });

  await recorder.step("Open the specific flow URL", async () => {
    await page.goto("/admin/agents/abc-123");
  });

  await recorder.step("Assert form fields are populated from the loaded agent", async () => {
    await expect(page.locator('[name="name"]')).toHaveValue("Data Summarizer");
    await expect(page.locator('[name="description"]')).toHaveValue("Loads a specific flow for editing.");
    await expect(page.getByRole("button", { name: "Save" })).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_load_success");
  await recorder.save(testInfo);
});
