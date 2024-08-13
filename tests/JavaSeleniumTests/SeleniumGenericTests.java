import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class SeleniumGenericTests {
    protected static WebDriver driver;
    protected static final String SELENIUM_GRID_PROTOCOL = System.getProperty("SELENIUM_GRID_PROTOCOL", "http");
    protected static String SELENIUM_GRID_HOST = System.getProperty("SELENIUM_GRID_HOST", "localhost");
    protected static final Integer SELENIUM_GRID_PORT = Integer.parseInt(System.getProperty("SELENIUM_GRID_PORT", "4444"));
    protected static final String SELENIUM_GRID_USERNAME = System.getProperty("SELENIUM_GRID_USERNAME", "");
    protected static final String SELENIUM_GRID_PASSWORD = System.getProperty("SELENIUM_GRID_PASSWORD", "");
    protected static final boolean SELENIUM_GRID_TEST_HEADLESS = Boolean.parseBoolean(System.getProperty("SELENIUM_GRID_TEST_HEADLESS", "false"));
    protected static final boolean SELENIUM_ENABLE_MANAGED_DOWNLOADS = Boolean.parseBoolean(System.getProperty("SELENIUM_ENABLE_MANAGED_DOWNLOADS", "true"));
    protected static final long WEB_DRIVER_WAIT_TIMEOUT = Long.parseLong(System.getProperty("WEB_DRIVER_WAIT_TIMEOUT", "60"));
    protected static final Integer TEST_DELAY_AFTER_TEST = Integer.parseInt(System.getProperty("TEST_DELAY_AFTER_TEST", "0"));
    protected static final String TEST_NODE_RELAY = System.getProperty("TEST_NODE_RELAY", "false");
    protected static final String TEST_ANDROID_PLATFORM_API = System.getProperty("TEST_ANDROID_PLATFORM_API", "");

    public SeleniumGenericTests() throws Exception {
        if (!SELENIUM_GRID_USERNAME.isEmpty() && !SELENIUM_GRID_PASSWORD.isEmpty()) {
            SELENIUM_GRID_HOST = String.format("%s:%s@%s", SELENIUM_GRID_USERNAME, SELENIUM_GRID_PASSWORD, SELENIUM_GRID_HOST);
        }
        if (TEST_NODE_RELAY.equals("Android")) {
            Thread.sleep(90 * 1000L);
        }
    }

    public void testTitle() {
        driver.get("https://the-internet.herokuapp.com");
        assertEquals("The Internet", driver.getTitle());
    }

    public void testWithFrames() {
        driver.get("https://the-internet.herokuapp.com/nested_frames");
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(WEB_DRIVER_WAIT_TIMEOUT));
        wait.until(ExpectedConditions.frameToBeAvailableAndSwitchToIt("frame-top"));
        wait.until(ExpectedConditions.frameToBeAvailableAndSwitchToIt("frame-middle"));
        assertEquals(driver.findElement(By.id("content")).getText(), "MIDDLE");
    }

    public void testSelectFromADropdown() {
        driver.get("https://the-internet.herokuapp.com/dropdown");
        WebElement dropdownList = driver.findElement(By.id("dropdown"));
        List<WebElement> options = dropdownList.findElements(By.tagName("option"));
        for (WebElement option : options) {
            if (option.getText().equals("Option 1")) {
                option.click();
                break;
            }
        }
        for (WebElement option : options) {
            if (option.isSelected()) {
                assertEquals(option.getText(), "Option 1");
            }
        }
    }
}

