import unittest

from check_clerk_production_auth import verify_google_client_ids


class VerifyGoogleClientIdsTests(unittest.TestCase):
    def test_skips_google_validation_when_preflight_has_only_clerk_values(self):
        self.assertEqual(verify_google_client_ids({}), [])

    def test_accepts_matching_web_ios_and_reversed_ids(self):
        values = {
            "GOOGLE_WEB_CLIENT_ID": "web-id.apps.googleusercontent.com",
            "GOOGLE_IOS_CLIENT_ID": "ios-id.apps.googleusercontent.com",
            "GOOGLE_IOS_REVERSED_CLIENT_ID": "com.googleusercontent.apps.ios-id",
        }

        self.assertEqual(verify_google_client_ids(values), [])

    def test_rejects_a_reversed_scheme_for_a_different_ios_client(self):
        values = {
            "GOOGLE_WEB_CLIENT_ID": "web-id.apps.googleusercontent.com",
            "GOOGLE_IOS_CLIENT_ID": "ios-id.apps.googleusercontent.com",
            "GOOGLE_IOS_REVERSED_CLIENT_ID": "com.googleusercontent.apps.other-id",
        }

        self.assertIn(
            "GOOGLE_IOS_REVERSED_CLIENT_ID does not match GOOGLE_IOS_CLIENT_ID",
            verify_google_client_ids(values),
        )

    def test_rejects_missing_or_non_google_client_ids(self):
        failures = verify_google_client_ids(
            {
                "GOOGLE_WEB_CLIENT_ID": "web-id.invalid",
                "GOOGLE_IOS_CLIENT_ID": "",
                "GOOGLE_IOS_REVERSED_CLIENT_ID": "custom.scheme",
            }
        )

        self.assertIn(
            "GOOGLE_WEB_CLIENT_ID is missing or is not a Google OAuth client ID",
            failures,
        )
        self.assertIn(
            "GOOGLE_IOS_CLIENT_ID is missing or is not a Google OAuth client ID",
            failures,
        )
        self.assertIn(
            "GOOGLE_IOS_REVERSED_CLIENT_ID is missing or is not a Google callback scheme",
            failures,
        )


if __name__ == "__main__":
    unittest.main()
