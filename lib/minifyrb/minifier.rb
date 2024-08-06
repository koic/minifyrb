# frozen_string_literal: true

require 'prism'

module Minifyrb
  class Minifier
    AFTER_SPACE_REQUIRED_KEYWORDS = %i(
      KEYWORD_ALIAS KEYWORD_AND KEYWORD_BEGIN KEYWORD_BREAK KEYWORD_CASE KEYWORD_CLASS KEYWORD_DEF KEYWORD_DO KEYWORD_ELSE
      KEYWORD_ELSIF KEYWORD_ENSURE KEYWORD_FOR KEYWORD_IF KEYWORD_IF_MODIFIER KEYWORD_IN KEYWORD_MODULE KEYWORD_NEXT
      KEYWORD_NOT KEYWORD_OR KEYWORD_REDO KEYWORD_RESCUE KEYWORD_RESCUE_MODIFIER KEYWORD_RETURN KEYWORD_SUPER KEYWORD_THEN
      KEYWORD_UNDEF KEYWORD_UNLESS KEYWORD_UNLESS_MODIFIER KEYWORD_UNTIL KEYWORD_UNTIL_MODIFIER KEYWORD_WHEN KEYWORD_WHILE
      KEYWORD_WHILE_MODIFIER KEYWORD_YIELD
    )
    BEFORE_SPACE_REQUIRED_KEYWORDS = %i(
      KEYWORD_AND KEYWORD_DO KEYWORD_IF_MODIFIER KEYWORD_IN KEYWORD_OR KEYWORD_RESCUE_MODIFIER KEYWORD_THEN
      KEYWORD_UNLESS_MODIFIER KEYWORD_UNTIL_MODIFIER KEYWORD_WHILE_MODIFIER
    )
    NUMERIC_LITERAL_TYPES = %i(FLOAT FLOAT_RATIONAL INTEGER INTEGER_RATIONAL)
    NO_DELIMITER_VALUE_TYPES = %i(CONSTANT IDENTIFIER) + NUMERIC_LITERAL_TYPES
    REQUIRE_SPACE_AFTER_IDENTIFIER_TYPES = %i(KEYWORD_SELF KEYWORD_TRUE KEYWORD_FALSE KEYWORD_NIL METHOD_NAME) + NUMERIC_LITERAL_TYPES

    def initialize(source, filepath: nil)
      result = Prism.lex(source)
      raise SyntaxError, filepath || 'compile error' unless result.errors.empty?

      @tokens = result.value

      @in_heredoc = false
      @string_quote = nil
      @minified_values = []
      @heredoc_content_tokens = []
    end

    def minify
      squiggly_heredoc = false
      prev_token = nil

      @tokens.each_cons(2) do |(token, _lex_state), (next_token, _next_lex_state)|
        case token.type
        when :COMMENT
          if prev_token && prev_token.location.start_line < next_token.location.start_line && prev_token.type == :IDENTIFIER && next_token.type == :IDENTIFIER
            append_token_value_to_minified_values(';')
          elsif prev_token && prev_token.location.start_line == token.location.start_line && token.location.start_line < next_token.location.start_line || next_token.type == :EOF
            append_token_value_to_minified_values("\n")
          end
        when :IDENTIFIER
          append_token_to_minified_values(token)

          if REQUIRE_SPACE_AFTER_IDENTIFIER_TYPES.include?(next_token.type)
            append_token_value_to_minified_values(' ')
          end
        when :IGNORED_NEWLINE, :EMBDOC_BEGIN, :EMBDOC_LINE, :EMBDOC_END
          # noop
        when :KEYWORD_END
          if NO_DELIMITER_VALUE_TYPES.include?(prev_token.type) && prev_token.location.start_line == token.location.start_line
            append_token_value_to_minified_values(' ')
          end
          append_token_to_minified_values(token)
        when :HEREDOC_START
          @in_heredoc = true
          squiggly_heredoc = token.value.start_with?('<<~')
          @string_quote = if token.value.end_with?("'")
            "'"
          elsif token.value.end_with?('`')
            '`'
          else
            '"'
          end

          @minified_values << (@string_quote == '`' ? '`' : '"')
        when :HEREDOC_END
          heredoc_contents = @heredoc_content_tokens.join

          if squiggly_heredoc
            lines = heredoc_contents.lines

            minimum_indentation_length = lines.map { |line|
              line.match(/\A(?<indentation_spaces> *)/)[:indentation_spaces].length
            }.min

            indentation = ' ' * minimum_indentation_length

            heredoc_contents = lines.map { |line| line.delete_prefix(indentation) }
          end

          @minified_values << heredoc_contents
          @minified_values << (@string_quote == '`' ? '`' : '"')

          @heredoc_content_tokens.clear
          @in_heredoc = false
        when :QUESTION_MARK
          # NOTE: Prevent syntax errors by converting `cond? ? x : y` to `cond??x:y`.
          token_value = if prev_token.value.end_with?('?')
            "#{token.value} "
          else
            # NOTE: Require both spaces to prevent syntax error of `foo==bar?x:y`.
            " #{token.value} "
          end

          append_token_value_to_minified_values(token_value)
        when :COLON
          # NOTE: Prevent syntax errors by converting `cond(arg) ? x : y` to `cond(arg)?x:y`.
          append_token_value_to_minified_values("#{token.value} ")
        when :UCOLON_COLON
          append_token_value_to_minified_values(' ') if prev_token.type == :IDENTIFIER || prev_token.type == :METHOD_NAME

          append_token_to_minified_values(token)
        when :BANG_TILDE
          append_token_value_to_minified_values(' ') if prev_token.type == :IDENTIFIER

          append_token_to_minified_values(token)
        when :LABEL
          append_token_value_to_minified_values(' ') if prev_token.type == :IDENTIFIER

          append_token_to_minified_values(token)

          append_token_value_to_minified_values(' ') if next_token.type == :SYMBOL_BEGIN
        when :EQUAL, :EQUAL_EQUAL, :EQUAL_EQUAL_EQUAL, :EQUAL_GREATER
          token_value = (prev_token.value.end_with?('*', '<', '=', '>', '?') ? " #{token.value}" : token.value)

          append_token_value_to_minified_values(token_value)
        when :STRING_BEGIN, :REGEXP_BEGIN, :PERCENT_LOWER_X, :PERCENT_LOWER_W, :PERCENT_LOWER_I, :PERCENT_UPPER_W, :PERCENT_UPPER_I
          append_token_value_to_minified_values(' ') if token.value.start_with?('%')

          append_token_to_minified_values(token)
        when :KEYWORD_DEF
          append_token_value_to_minified_values(' ') if prev_token&.type == :IDENTIFIER

          append_token_to_minified_values(token)
        when :NEWLINE
          token_value = if next_token.type == :EOF
            token.value
          elsif next_token.type == :PARENTHESIS_RIGHT || next_token.type == :BRACKET_RIGHT || next_token.type == :BRACE_RIGHT
            # noop
          else
            ';'
          end

          append_token_value_to_minified_values(token_value)
        else
          append_token_to_minified_values(token)
        end

        if padding_required?(token, next_token)
          append_token_value_to_minified_values(' ')
        end

        prev_token = token
      end

      @minified_values.join
    end

    private

    def append_token_to_minified_values(token)
      if @in_heredoc
        token_value = if token.type == :STRING_CONTENT
          token.value.gsub!(/(?<!\\)"/, '\\\"') # Escape quotes.
          if @in_heredoc && @string_quote == "'"
            token.value.gsub!(/\#{/, '\\#{') # FIXME: Dirty Hack for escape of string interpolation
          end
        end
        token_value ||= token.value

        @heredoc_content_tokens << token_value
      else
        @minified_values << token.value
      end
    end

    def append_token_value_to_minified_values(token_value)
      if @in_heredoc
        @heredoc_content_tokens << token_value
      else
        @minified_values << token_value
      end
    end

    def padding_required?(token, next_token)
      return true if token.type == :IDENTIFIER && (next_token.type == :IDENTIFIER || next_token.type == :CONSTANT)
      return false if token.type == :SYMBOL_BEGIN || next_token.type == :PARENTHESIS_LEFT

      AFTER_SPACE_REQUIRED_KEYWORDS.include?(token.type) || BEFORE_SPACE_REQUIRED_KEYWORDS.include?(next_token.type)
    end
  end
end
