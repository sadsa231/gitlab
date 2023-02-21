# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :editor do
    describe 'Testing group wiki file upload' do
      let(:initial_wiki) { Resource::Wiki::GroupPage.fabricate_via_api! }
      let(:page_title) { 'Content Editor Page' }
      let(:heading_text) { 'My New Heading' }
      let(:image_file_name) { 'testfile.png' }

      before do
        Flow::Login.sign_in
      end

      it 'by creating a formatted page with an image uploaded',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/375655' do
        initial_wiki.visit!

        EE::Page::Group::Wiki::Show.perform(&:click_new_page)

        EE::Page::Group::Wiki::Edit.perform do |edit|
          edit.set_title(page_title)
          edit.use_new_editor
          edit.add_heading('Heading 1', heading_text)
          edit.upload_image(File.join(Runtime::Path.fixtures_path, 'designs', image_file_name))
        end

        EE::Page::Group::Wiki::Edit.perform(&:click_submit)

        EE::Page::Group::Wiki::Show.perform do |wiki|
          aggregate_failures 'page shows expected content' do
            expect(wiki).to have_title(page_title)
            expect(wiki).to have_heading('h1', heading_text)
            expect(wiki).to have_image(image_file_name)
          end
        end
      end
    end
  end
end
