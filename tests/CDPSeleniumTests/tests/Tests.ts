const { test, expect } = require('@playwright/test');

function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

test.describe('SeleniumGenericTests', () => {
    test('test_title', async ({ page }) => {
        await page.goto('https://the-internet.herokuapp.com');
        await expect(page).toHaveTitle('The Internet');
        await sleep(15000);
    });

    test('test_with_frames', async ({ page }) => {
        await page.goto('http://the-internet.herokuapp.com/nested_frames');
        const frame = page.frameLocator('frame[name="frame-top"]').frameLocator('frame[name="frame-middle"]');
        await expect(frame.locator('#content')).toHaveText('MIDDLE');
        await sleep(15000);
    });
});
