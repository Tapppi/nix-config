-- Fixture standing in for the store-generated targets.lua. Deliberately its
-- own copy rather than the real one: these tests assert on specific keys and
-- profiles, and should not start failing because the host's target list grew.
return {
  {
    key = "b",
    label = "Personal",
    bundle = "com.brave.Browser",
    profileDir = "Default",
  },
  {
    key = "v",
    label = "Company",
    bundle = "com.google.Chrome",
    profileDir = "Profile 1",
  },
  {
    key = "c",
    label = "Client",
    bundle = "com.google.Chrome",
    profileDir = "Profile 2",
  },
}
