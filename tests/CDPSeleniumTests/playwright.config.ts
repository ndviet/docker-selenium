import type {PlaywrightTestConfig} from '@playwright/test';
import * as dotenv from 'dotenv';

dotenv.config();

const config: PlaywrightTestConfig = {
    timeout: 1500000,
    testMatch: ["tests/Tests.ts"],
    use: {
        headless: false,
        screenshot: "on",
        video: "on"
    },
    reporter: [["dot"], ["json", {
        outputFile: "jsonReports/jsonREport.json"
    }], ["html", {
        open: "never"
    }]]
};

export default config;
