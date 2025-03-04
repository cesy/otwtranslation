Feature: Languages
  In order to have languages
  As a translation admin
  I want to view and manage languages

  Scenario: View languages
    Given I am a translation admin
    And I have the language "Deutsch" with short "de"

    When I go to the language table
    Then I should see the heading "Language Table"
    And I should see the language name "Deutsch"
    And I should see the language short "de"

    When I follow "Deutsch"
    Then I should see the heading "Show Language"
    And I should see the language short "de"
    And I should see the language name "Deutsch"

  Scenario: Add a language
    Given I am a translation admin
    And I am on the language table

    When I follow "Add language"
    Then I should see the heading "Add Language"

    When I fill in the following:
      | Short: | de      |
      | Name:  | Deutsch |
    And I uncheck "Right to left?"
    And I check "Translation visible?"
    And I press "Add language"
    Then I should see "Language successfully created."
    And I should see the heading "Show Language"
    And I should see the language short "de"
    And I should see the language name "Deutsch"
    And I should see right to left set to "no"
    And I should see translations visible set to "yes"







