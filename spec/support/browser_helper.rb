# Helpers for feature specs which need to change or look into the browser. They
# use the Chrome DevTools protocol, so they work only with the Chrome driver.
# Everything they change is reset after each spec, the browser is shared.
module BrowserHelper
  # Runs the pages in another time zone, for example 'America/New_York'
  def emulate_time_zone(time_zone)
    devtools('Emulation.setTimezoneOverride', timezoneId: time_zone)
    @browser_time_zone_changed = true
  end

  # Collects uncaught errors and unhandled promise rejections, read them with
  # `js_errors`. Call it before `visit`.
  def collect_js_errors
    add_script_before_page_load(<<~JS)
      window.collectedErrors = [];
      window.addEventListener('error', (event) => window.collectedErrors.push(String(event.message)));
      window.addEventListener('unhandledrejection', (event) => window.collectedErrors.push(String(event.reason)));
    JS
  end

  def js_errors
    page.evaluate_script('window.collectedErrors')
  end

  # Makes the browser clock movable with `move_browser_clock`, for example to
  # look at a page which stays open over midnight. Call it before `visit`.
  def install_browser_clock
    add_script_before_page_load(<<~JS)
      (() => {
        const RealDate = Date;
        const now = () => RealDate.now() + window.browserClockOffset;
        window.browserClockOffset = 0;
        window.Date = new Proxy(RealDate, {
          construct: (target, args) => (args.length === 0 ? new target(now()) : new target(...args)),
          apply: () => new RealDate(now()).toString(),
          get: (target, property) => (property === 'now' ? now : Reflect.get(target, property)),
        });
      })();
    JS
  end

  def move_browser_clock(duration)
    page.execute_script("window.browserClockOffset += #{duration.to_i * 1000}")
  end

  # How many listeners of this type are on `window`, DevTools sees all of them
  def window_event_listener_count(type)
    window = devtools('Runtime.evaluate', expression: 'window')
    listeners = devtools('DOMDebugger.getEventListeners', objectId: window.dig('result', 'objectId'))

    listeners['listeners'].count { |listener| listener['type'] == type }
  end

  def reset_browser_changes
    if @browser_time_zone_changed
      devtools('Emulation.setTimezoneOverride', timezoneId: '')
      @browser_time_zone_changed = false
    end

    (@browser_page_scripts || []).each do |identifier|
      devtools('Page.removeScriptToEvaluateOnNewDocument', identifier: identifier)
    end
    @browser_page_scripts = []
  end

  private

  def add_script_before_page_load(source)
    result = devtools('Page.addScriptToEvaluateOnNewDocument', source: source)
    (@browser_page_scripts ||= []) << result['identifier']
  end

  def devtools(command, **params)
    page.driver.browser.execute_cdp(command, **params)
  end
end

RSpec.configure do |config|
  config.include BrowserHelper, type: :feature

  config.after(:each, type: :feature) do
    reset_browser_changes
  end
end
