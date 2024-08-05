# frozen_string_literal: true

RSpec.describe Minifyrb::Minifier do
  describe '#minify' do
    subject(:minified_ruby) { described_class.new(source).minify }

    context 'when using an incorrect syntax' do
      let(:source) do
        <<~RUBY
          foo('arg
        RUBY
      end

      it 'raises syntax error' do
        expect { minified_ruby }.to raise_error(SyntaxError)
      end
    end

    context 'when using single-line comments' do
      let(:source) do
        <<~RUBY
          # comment
          foo 'arg'
        RUBY
      end

      it 'does not contain comments' do
        expect(minified_ruby).to eq <<~RUBY
          foo'arg'
        RUBY
      end
    end

    context 'when using multi-line comments' do
      let(:source) do
        <<~RUBY
          =begin
            comment
          =end
          foo 'arg'
        RUBY
      end

      it 'does not contain comments' do
        expect(minified_ruby).to eq <<~RUBY
          foo'arg'
        RUBY
      end
    end

    context 'when using tailing comments' do
      let(:source) do
        <<~RUBY
          foo 'arg' # comment
          bar 'arg' # comment
        RUBY
      end

      it 'keeps multiline' do
        expect(minified_ruby).to eq <<~RUBY
          foo'arg'
          bar'arg'
        RUBY
      end
    end

    context 'when using blank line' do
      let(:source) do
        <<~RUBY
          foo

          bar
        RUBY
      end

      it 'does not contain a blank line' do
        expect(minified_ruby).to eq <<~RUBY
          foo;bar
        RUBY
      end
    end

    context 'when calling method with around spaces' do
      let(:source) do
        <<~RUBY
          1 + 1
        RUBY
      end

      it 'does not contain spaces' do
        expect(minified_ruby).to eq <<~RUBY
          1+1
        RUBY
      end
    end

    context 'when using line break method call parenthesis' do
      let(:source) do
        <<~RUBY
          foo(
            arg
          )
        RUBY
      end

      it 'does not contain a semicolon before right-parenthesis' do
        expect(minified_ruby).to eq <<~RUBY
          foo(arg)
        RUBY
      end
    end

    context 'when using local variable without method call parenthesis' do
      let(:source) do
        <<~RUBY
          val = 'str'
          foo val
        RUBY
      end

      it 'contain a space after method call' do
        expect(minified_ruby).to eq <<~RUBY
          val='str';foo val
        RUBY
      end
    end

    context 'when calling method with constant argument' do
      let(:source) do
        <<~RUBY
          include Foo
        RUBY
      end

      it 'contain a space after method call' do
        expect(minified_ruby).to eq <<~RUBY
          include Foo
        RUBY
      end
    end

    context 'when calling nexted methods without method call parenthesis' do
      let(:source) do
        <<~RUBY
          foo bar baz
        RUBY
      end

      it 'contain a space between method calls' do
        expect(minified_ruby).to eq <<~RUBY
          foo bar baz
        RUBY
      end
    end

    context 'when calling method chain with leading dot and there is a comment' do
      let(:source) do
        <<~RUBY
          foo
            # comment
            .bar
        RUBY
      end

      it 'does not contain a comment and a blank line before method chain' do
        expect(minified_ruby).to eq <<~RUBY
          foo.bar
        RUBY
      end
    end

    context 'when using local variable with method call parenthesis' do
      let(:source) do
        <<~RUBY
          val = 'str'
          foo(val)
        RUBY
      end

      it 'contain a space after method call' do
        expect(minified_ruby).to eq <<~RUBY
          val='str';foo(val)
        RUBY
      end
    end

    context 'when using one-liner `do` `end` block call' do
      let(:source) do
        <<~RUBY
          foo do end
        RUBY
      end

      it 'contain spaces around the keywords' do
        expect(minified_ruby).to eq <<~RUBY
          foo do end
        RUBY
      end
    end

    context 'when using `if` expression' do
      let(:source) do
        <<~RUBY
          if cond
          end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          if cond;end
        RUBY
      end
    end

    context 'when using `if`..`then` expression' do
      let(:source) do
        <<~RUBY
          if cond then foo
          end
        RUBY
      end

      it 'contain a space around the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          if cond then foo;end
        RUBY
      end
    end

    context 'when using one-liner `if`..`then` expression' do
      let(:source) do
        <<~RUBY
          if cond then foo end
        RUBY
      end

      it 'contain a space around the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          if cond then foo end
        RUBY
      end
    end

    context 'when using `if`...`elsif` expression' do
      let(:source) do
        <<~RUBY
          if cond
          elsif cond2
          end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          if cond;elsif cond2;end
        RUBY
      end
    end

    context 'when using `unless` expression' do
      let(:source) do
        <<~RUBY
          unless cond
          end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          unless cond;end
        RUBY
      end
    end

    context 'when using `if` modifier' do
      let(:source) do
        <<~RUBY
          42 if cond
        RUBY
      end

      it 'contain a space before the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          42 if cond
        RUBY
      end
    end

    context 'when using `unless` modifier' do
      let(:source) do
        <<~RUBY
          42 unless cond
        RUBY
      end

      it 'contain a space before the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          42 unless cond
        RUBY
      end
    end

    context 'when using `case`...`when` expression' do
      let(:source) do
        <<~RUBY
          case var
          when cond
          end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          case var;when cond;end
        RUBY
      end
    end

    context 'when using `case`...`in` expression' do
      let(:source) do
        <<~RUBY
          case var
          in cond
          end
        RUBY
      end

      # TODO: Remove the redundant space before `in` keyword.
      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          case var; in cond;end
        RUBY
      end
    end

    context 'when using ternary oprator' do
      let(:source) do
        <<~RUBY
          cond(arg) ? x : y
        RUBY
      end

      # NOTE: Prevent syntax error of `cond(arg)?x:y`.
      it 'contain a space after the semicolon' do
        expect(minified_ruby).to eq <<~RUBY
          cond(arg)?x: y
        RUBY
      end
    end

    context 'when using `while` expression' do
      let(:source) do
        <<~RUBY
          while cond
          end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          while cond;end
        RUBY
      end
    end

    context 'when using `until` expression' do
      let(:source) do
        <<~RUBY
          until cond
          end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          until cond;end
        RUBY
      end
    end

    context 'when using `while` modifier' do
      let(:source) do
        <<~RUBY
          42 while cond
        RUBY
      end

      it 'contain a space before the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          42 while cond
        RUBY
      end
    end

    context 'when using `until` modifier' do
      let(:source) do
        <<~RUBY
          42 until cond
        RUBY
      end

      it 'contain a space before the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          42 until cond
        RUBY
      end
    end

    context 'when using `for`' do
      let(:source) do
        <<~RUBY
          for item in items
          end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          for item in items;end
        RUBY
      end
    end

    context 'when using `and`' do
      let(:source) do
        <<~RUBY
          foo and bar
        RUBY
      end

      it 'contain a space before the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          foo and bar
        RUBY
      end
    end

    context 'when using `or`' do
      let(:source) do
        <<~RUBY
          foo or bar
        RUBY
      end

      it 'contain a space before the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          foo or bar
        RUBY
      end
    end

    context 'when using `not`' do
      let(:source) do
        <<~RUBY
          not foo
        RUBY
      end

      it 'contain a space before the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          not foo
        RUBY
      end
    end

    context 'when using `&&`' do
      let(:source) do
        <<~RUBY
          foo && bar
        RUBY
      end

      it 'does not contain spaces around the operator' do
        expect(minified_ruby).to eq <<~RUBY
          foo&&bar
        RUBY
      end
    end

    context 'when using `||`' do
      let(:source) do
        <<~RUBY
          foo || bar
        RUBY
      end

      it 'does not contain spaces around the operator' do
        expect(minified_ruby).to eq <<~RUBY
          foo||bar
        RUBY
      end
    end

    context 'when using `&`' do
      let(:source) do
        <<~RUBY
          foo & bar
        RUBY
      end

      it 'does not contain spaces around the operator' do
        expect(minified_ruby).to eq <<~RUBY
          foo&bar
        RUBY
      end
    end

    context 'when using `|`' do
      let(:source) do
        <<~RUBY
          foo | bar
        RUBY
      end

      it 'does not contain spaces around the operator' do
        expect(minified_ruby).to eq <<~RUBY
          foo|bar
        RUBY
      end
    end

    context 'when using `!`' do
      let(:source) do
        <<~RUBY
          ! foo
        RUBY
      end

      it 'does not contain spaces around the operator' do
        expect(minified_ruby).to eq <<~RUBY
          !foo
        RUBY
      end
    end

    context 'when using `in` pattern matching' do
      let(:source) do
        <<~RUBY
          expr in pattern
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          expr in pattern
        RUBY
      end
    end

    context 'when using `=>` pattern matching' do
      let(:source) do
        <<~RUBY
          expr => pattern
        RUBY
      end

      it 'contain a space after the operator' do
        expect(minified_ruby).to eq <<~RUBY
          expr=>pattern
        RUBY
      end
    end

    context 'when using `return`' do
      let(:source) do
        <<~RUBY
          foo do return bar end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          foo do return bar end
        RUBY
      end
    end

    context 'when using `next`' do
      let(:source) do
        <<~RUBY
          foo do next bar end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          foo do next bar end
        RUBY
      end
    end

    context 'when using `yield`' do
      let(:source) do
        <<~RUBY
          def x() = foo do yield bar end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          def x()=foo do yield bar end
        RUBY
      end
    end

    context 'when using `yield` with arguments' do
      let(:source) do
        <<~RUBY
          def x() = foo do
            yield(x, y)
          end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          def x()=foo do yield(x,y);end
        RUBY
      end
    end

    context 'when using `break`' do
      let(:source) do
        <<~RUBY
          foo do break bar end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          foo do break bar end
        RUBY
      end
    end

    context 'when using `redo`' do
      let(:source) do
        <<~RUBY
          foo do redo end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          foo do redo end
        RUBY
      end
    end

    context 'when using `retry`' do
      let(:source) do
        <<~RUBY
          foo rescue retry if cond
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          foo rescue retry if cond
        RUBY
      end
    end

    context 'when using `rescue`' do
      let(:source) do
        <<~RUBY
          begin
          rescue CustomError => e
          else
          ensure
          end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          begin rescue CustomError=>e;else ensure end
        RUBY
      end
    end

    context 'when using one-liner `rescue`' do
      let(:source) do
        <<~RUBY
          foo rescue nil
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          foo rescue nil
        RUBY
      end
    end

    context 'when using one-liner `begin` with integer' do
      let(:source) do
        <<~RUBY
          begin 42 end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          begin 42 end
        RUBY
      end
    end

    context 'when using one-liner `begin` with float' do
      let(:source) do
        <<~RUBY
          begin 4.2 end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          begin 4.2 end
        RUBY
      end
    end

    context 'when using one-liner `begin` with rational' do
      let(:source) do
        <<~RUBY
          begin 42r end
        RUBY
      end

      it 'contain a space after the keyword' do
        expect(minified_ruby).to eq <<~RUBY
          begin 42r end
        RUBY
      end
    end

    context 'when using `super` with argument without method call parenthesis' do
      let(:source) do
        <<~RUBY
          def foo arg
            super arg
          end
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          def foo arg;super arg;end
        RUBY
      end
    end

    context 'when defining method' do
      let(:source) do
        <<~RUBY
          def foo
          end
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          def foo;end
        RUBY
      end
    end

    context 'when defining singleton method' do
      let(:source) do
        <<~RUBY
          def self.foo
          end
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          def self.foo;end
        RUBY
      end
    end

    context 'when defining class' do
      let(:source) do
        <<~RUBY
          class Foo
          end
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          class Foo;end
        RUBY
      end
    end

    context 'when defining one-liner method' do
      let(:source) do
        <<~RUBY
          def foo() end
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          def foo()end
        RUBY
      end
    end

    context 'when defining one-liner class' do
      let(:source) do
        <<~RUBY
          class Foo end
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          class Foo end
        RUBY
      end
    end

    context 'when defining module' do
      let(:source) do
        <<~RUBY
          module Foo
          end
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          module Foo;end
        RUBY
      end
    end

    context 'when defining one-liner module' do
      let(:source) do
        <<~RUBY
          module Foo end
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          module Foo end
        RUBY
      end
    end

    context 'when using `alias`' do
      let(:source) do
        <<~RUBY
          alias new old
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          alias new old
        RUBY
      end
    end

    context 'when using `undef`' do
      let(:source) do
        <<~RUBY
          undef foo
        RUBY
      end

      it 'contains spaces' do
        expect(minified_ruby).to eq <<~RUBY
          undef foo
        RUBY
      end
    end

    context 'when using string literal' do
      let(:source) do
        '"  text  "'
      end

      it 'convert to compatible string' do
        expect(minified_ruby).to eq '"  text  "'
      end
    end

    context 'when using heredoc `<<HEREDOC`' do
      let(:source) do
        <<~RUBY
          <<HEREDOC
            text
          HEREDOC
        RUBY
      end

      it 'convert to compatible string' do
        expect(minified_ruby).to eq %("  text\n"\n)
      end
    end

    context "when using heredoc `<<'HEREDOC'`" do
      let(:source) do
        <<~RUBY
          <<'HEREDOC'
            text
          HEREDOC
        RUBY
      end

      it 'convert to compatible string' do
        expect(minified_ruby).to eq %('  text\n'\n)
      end
    end

    context 'when using heredoc `<<`HEREDOC``' do
      let(:source) do
        <<~RUBY
          <<`HEREDOC`
            command
          HEREDOC
        RUBY
      end

      it 'convert to compatible string' do
        expect(minified_ruby).to eq %(`  command\n`\n)
      end
    end

    context 'when using heredoc `<<-HEREDOC`' do
      let(:source) do
        <<~RUBY
          <<-HEREDOC
            text
          HEREDOC
        RUBY
      end

      it 'convert to compatible string' do
        expect(minified_ruby).to eq %("  text\n"\n)
      end
    end

    context 'when using squiggly single-line heredoc `<<~HEREDOC`' do
      let(:source) do
        <<~RUBY
          <<~HEREDOC
            foo
          HEREDOC
        RUBY
      end

      it 'convert to compatible string' do
        expect(minified_ruby).to eq %("foo\n"\n)
      end
    end

    context 'when using first line indented squiggly heredoc `<<~HEREDOC`' do
      let(:source) do
        <<~RUBY
          <<~HEREDOC
            foo
              bar
          HEREDOC
        RUBY
      end

      it 'convert to compatible string' do
        expect(minified_ruby).to eq %("foo\n  bar\n"\n)
      end
    end

    context 'when using second line indented squiggly heredoc `<<~HEREDOC`' do
      let(:source) do
        <<~RUBY
          <<~HEREDOC
              foo
            bar
          HEREDOC
        RUBY
      end

      it 'convert to compatible string' do
        expect(minified_ruby).to eq %("  foo\nbar\n"\n)
      end
    end
  end
end
