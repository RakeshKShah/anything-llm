import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import {
  setupAdminAgentSkillsPage,
  mockGoogleAgentSkillStatuses,
} from "../../helpers/mock-api.js";

test("google calendar capability shows configured status when deploymentId and apiKey are set", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "google_calendar_capability_configured",
    testTitle: "Google Calendar capability shows configured status when deploymentId and apiKey are set",
  });

  await recorder.step("Set up admin agent skills page and Google Calendar configured mocks", async () => {
    await setupAdminAgentSkillsPage(page);
    await mockGoogleAgentSkillStatuses(page, {
      gmail: {
        status: 200,
        body: {
          success: true,
          isConfigured: false,
          config: { deploymentId: "", apiKey: "" },
        },
      },
      calendar: {
        status: 200,
        body: {
          success: true,
          isConfigured: true,
          config: {
            deploymentId: "AKfycb-calendar-deployment",
            apiKey: "********",
          },
        },
      },
    });
  });

  await recorder.step("Load the admin agent skills page", async () => {
    await page.goto("/settings/agents");
    await expect(page.getByRole("heading", { name: "App Integrations" })).toBeVisible();
  });

  await recorder.step("Open the Google Calendar skill panel", async () => {
    await page.getByText("Google Calendar", { exact: true }).click();
    await expect(page.getByText("Configuration", { exact: true })).toBeVisible();
  });

  await recorder.step("Verify the Google Calendar capability shows configured status and masked credentials", async () => {
    await expect(page.getByText("Configured", { exact: true })).toBeVisible();
    await expect(page.getByDisplayValue("AKfycb-calendar-deployment")).toBeVisible();
    await expect(page.getByDisplayValue("********")).toBeVisible();
    await expect(page.getByText(/configuration required/i)).toHaveCount(0);
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:google_calendar_capability_configured");
  await recorder.save(testInfo);
});
