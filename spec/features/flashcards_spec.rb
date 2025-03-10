# frozen_string_literal: true

RSpec.describe "flash cards" do
  it "creates flash card lists when user is created" do
    user = create :guest

    expect(user.lists.unscoped.map(&:flashcard_section)).to match_array (1..5).to_a
    expect(user.lists.unscoped.map(&:to_s)).to match_array ["Fach 1", "Fach 2", "Fach 3", "Fach 4", "Fach 5"]
  end

  describe "adding words to the flash card lists" do
    let(:lecturer) { create :lecturer }
    let!(:learning_group) { create :learning_group, owner: lecturer }
    let(:word_list) { create :list, user: lecturer, visibility: :public }
    let(:user) { create :guest }
    let(:noun1) { create :noun, name: "Adler" }
    let(:noun2) { create :noun, name: "Bauer" }

    before do
      word_list.words << noun1
      word_list.words << noun2
      LearningGroupMembership.create!(learning_group:, user:, access: :granted)
      login_as lecturer
    end

    it "adds words to the first section and removes the word when list is removed" do
      visit learning_group_path(learning_group)
      click_on t("learning_groups.show.assign_list")
      expect(page).to have_content t("learning_pleas.new.title")
      click_on t("learning_pleas.new.assign")

      expect(learning_group.lists).to match_array [word_list]
      expect(user.flashcard_list(1).words).to match_array [noun1, noun2]

      login_as user
      visit flashcards_path
      expect(page).to have_content noun1.name
      expect(page).to have_content noun2.name

      # Remove list
      login_as lecturer
      visit learning_group_path(learning_group)
      within "##{dom_id(learning_group.learning_pleas.first)}" do
        click_on t("actions.remove")
      end

      login_as user
      visit flashcards_path
      expect(page).not_to have_content noun1.name
      expect(page).not_to have_content noun2.name
    end

    it "adds and removes words when modifying the list" do
      visit learning_group_path(learning_group)
      click_on t("learning_groups.show.assign_list")
      expect(page).to have_content t("learning_pleas.new.title")
      click_on t("learning_pleas.new.assign")

      expect(learning_group.lists).to match_array [word_list]
      expect(user.flashcard_list(1).words).to match_array [noun1, noun2]

      # Add new word
      noun3 = create :noun, name: "Baum"
      visit noun_path(noun3)
      select word_list.name
      click_on I18n.t("words.show.lists.add")

      login_as user
      visit flashcards_path
      expect(page).to have_content noun1.name
      expect(page).to have_content noun2.name
      expect(page).to have_content noun3.name

      # Remove word from list
      login_as lecturer
      visit list_path(word_list)
      within "##{dom_id(noun3)}" do
        click_on I18n.t("actions.remove")
      end

      login_as user
      visit flashcards_path
      expect(page).to have_content noun1.name
      expect(page).to have_content noun2.name
      expect(page).not_to have_content noun3.name
    end
  end
end
