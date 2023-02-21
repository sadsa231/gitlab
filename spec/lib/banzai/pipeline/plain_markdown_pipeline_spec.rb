# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::PlainMarkdownPipeline, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  describe 'backslash escapes', :aggregate_failures do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issue)   { create(:issue, project: project) }

    it 'converts all escapable punctuation to literals' do
      markdown = Banzai::Filter::MarkdownPreEscapeFilter::ESCAPABLE_CHARS.pluck(:escaped).join

      result = described_class.call(markdown, project: project)
      output = result[:output].to_html

      Banzai::Filter::MarkdownPreEscapeFilter::ESCAPABLE_CHARS.pluck(:char).each do |char|
        char = '&amp;' if char == '&'

        expect(output).to include("<span>#{char}</span>")
      end

      expect(result[:escaped_literals]).to be_truthy
    end

    it 'ensure we handle all the GitLab reference characters', :eager_load do
      reference_chars = ObjectSpace.each_object(Class).map do |klass|
        next unless klass.included_modules.include?(Referable)
        next unless klass.respond_to?(:reference_prefix)
        next unless klass.reference_prefix.length == 1

        klass.reference_prefix
      end.compact

      reference_chars.all? do |char|
        Banzai::Filter::MarkdownPreEscapeFilter::TARGET_CHARS.include?(char)
      end
    end

    it 'does not convert non-reference/latex punctuation to spans' do
      markdown = %q(\"\'\*\+\,\-\.\/\:\;\<\=\>\?\[\]\`\|) + %q[\(\)\\\\]

      result = described_class.call(markdown, project: project)
      output = result[:output].to_html

      expect(output).not_to include('<span>')
      expect(result[:escaped_literals]).to be_falsey
    end

    it 'does not convert other characters to literals' do
      markdown = %q(\→\A\a\ \3\φ\«)
      expected = '\→\A\a\ \3\φ\«'

      result = correct_html_included(markdown, expected)
      expect(result[:escaped_literals]).to be_falsey
    end

    describe 'backslash escapes are untouched in code blocks, code spans, autolinks, or raw HTML' do
      where(:markdown, :expected) do
        %q(`` \@\! ``)       | %q(<code>\@\!</code>)
        %q(    \@\!)         | %Q(<code>\\@\\!\n</code>)
        %Q(~~~\n\\@\\!\n~~~) | %Q(<code>\\@\\!\n</code>)
        %q($1+\$2$)          | %q(<code data-math-style="inline">1+\\$2</code>)
        %q(<http://example.com?find=\@>) | %q(<a href="http://example.com?find=%5C@">http://example.com?find=\@</a>)
        %q[<a href="/bar\@)">]           | %q[<a href="/bar%5C@)">]
      end

      with_them do
        it { correct_html_included(markdown, expected) }
      end
    end

    describe 'work in all other contexts, including URLs and link titles, link references, and info strings in fenced code blocks' do
      let(:markdown) { %Q(``` foo\\@bar\nfoo\n```) }

      it 'renders correct html' do
        correct_html_included(markdown, %Q(<pre data-sourcepos="1:1-3:3" lang="foo@bar"><code>foo\n</code></pre>))
      end

      where(:markdown, :expected) do
        %q![foo](/bar\@ "\@title")!            | %q(<a href="/bar@" title="@title">foo</a>)
        %Q![foo]\n\n[foo]: /bar\\@ "\\@title"! | %q(<a href="/bar@" title="@title">foo</a>)
      end

      with_them do
        it { correct_html_included(markdown, expected) }
      end
    end
  end

  def correct_html_included(markdown, expected)
    result = described_class.call(markdown, {})

    expect(result[:output].to_html).to include(expected)

    result
  end
end
