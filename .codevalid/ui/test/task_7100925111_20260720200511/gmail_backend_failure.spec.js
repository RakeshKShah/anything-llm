import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  mockGoogleAgentSkillStatuses,
} from "../../helpers/mock-api.js";

test("UI falls back to unconfigured state when Gmail status API fails", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "gmail_backend_failure",
    testTitle: "UI displays error when Gmail status API returns 500",
  });

  await recorder.step("Set up admin agent skills page and Gmail failure mocks", async () => {
    await setupAdminAgentSkillsPage(page);
    await mockGoogleAgentSkillStatuses(page, {
      gmail: {
        status: 500,
        body: {
          success: false,
          error: "Gmail status error",
        },
      },
      calendar: {
        status: 200,
        body: {
          success: true,
          isConfigured: false,
          config: { deploymentId: "", apiKey: "" },
        },
      },
    });
  });

  await recorder.step("Load the admin agent skills page", async () => {
    await page.goto("/settings/agents");
    await expect(page.getByRole("heading", { name: "App Integrations" })).toBeVisible();
  });

  await recorder.step("Open the Gmail skill panel", async () => {
    await page.getByText("Gmail", { exact: true }).click();
    await expect(page.getByText("Configuration", { exact: true })).toBeVisible();
  });

  await recorder.step("Verify the UI does not show configured credentials after backend failure", async () => {
    await expect(page.getByText("Configured", { exact: true })).toHaveCount(0);
    await expect(page.getByPlaceholder("AKfycb...")).toHaveValue("");
    await expect(page.getByPlaceholder("Your API key...")).toHaveValue("");
    await expect(page.getByText(/configuration required/i)).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:gmail_backend_failure");
  await recorder.save(testInfo);
});
