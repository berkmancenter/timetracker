Rails.application.config.middleware.use OmniAuth::Builder do
  provider :saml,
    #:assertion_consumer_service_url     => "consumer_service_url",
    :issuer                             => "harvard.edu",
    :idp_sso_target_url                 => "https://fed.huit.harvard.edu/idp/shibboleth",
    #:idp_sso_target_url_runtime_params  => {:original_request_param => :mapped_idp_param},
    :idp_cert                           => "-----BEGIN CERTIFICATE-----\nMIIDRDCCAiygAwIBAgIUdXfRRGHcHe0kqyWjt9pzdElroS8wDQYJKoZIhvcNAQEL\nBQAwIjEgMB4GA1UEAwwXa2V5LWlkcC5pYW0uaGFydmFyZC5lZHUwHhcNMTYwNjA5\nMjAyNDEyWhcNMzYwNjA5MjAyNDEyWjAiMSAwHgYDVQQDDBdrZXktaWRwLmlhbS5o\nYXJ2YXJkLmVkdTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAIr/Hd3R\ncDBNh5C2hi9GicY0LCOJDW34ndazmFZy5djYajqxoy7+RPDZwOlJdjIq7hpzxKvD\nK59dSLha60XfSSzqKpnQ8S/jcvpKnpW9UStMR7lGaIUTLSAEqHvguzR7iQt3wuKD\nFxGPxvQeO/z32F0wvmbmemI1XhLSIo1aJAOujsAFPex1K3QYTkBQDOiDqd9gatr9\nW163rx+Nd7BHpXaUWGQcLpkM7iMH9lgmWg4F4yvJLOV72ygOwb/YP7bnVog2B+VM\nAuX//TVhMHc3d4QOMS7zDDKexbG1kdlBuFrawV5betGnIywEFE9Du3RCH61Zhppd\nrhtfP+ie2tbqFlUCAwEAAaNyMHAwHQYDVR0OBBYEFHKP/f1hfPpCGc1DKMtXlWom\naAV7ME8GA1UdEQRIMEaCF2tleS1pZHAuaWFtLmhhcnZhcmQuZWR1hitodHRwczov\nL2ZlZC5odWl0LmhhcnZhcmQuZWR1L2lkcC9zaGliYm9sZXRoMA0GCSqGSIb3DQEB\nCwUAA4IBAQAFLHg4EBEDDeUhQi+QRVgbgmkiKkPSiZLeeDbmaWyELEr5kGye7Q6Z\nwcXDK3qHOQc6GRhBw13A7YqCuuhjgxD51hzlPvOy6HAmPkaqWuNfXl2QMxb1LNkY\n0WJiEHLOZvnpItV5mTgszzlTfg/rj1l8IfsBSYfSZjePIk7IIW4y0PsQG+mOCz4D\njrZDSJtefq5iaDcZKHGmAOex9osIjM2JJ7hUV52YV/ct+Ha6q+oBnzUo62lVGOsx\nzyNYEoUX1Q25f0lm72MYS7M4LifZ4sW3fF9OZClDelj2VcqAWHeMQhjkbtMyrTc5\n59SJSzhAtL9UdzpgB0Poym6nF34EgDtl-----END CERTIFICATE-----",
    #:idp_cert_fingerprint               => "E7:91:B2:E1:...",
    #:name_identifier_format             => "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
end
