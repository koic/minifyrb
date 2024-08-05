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
    NO_DELIMITER_VALUE_TYPES = %i(
      CONSTANT FLOAT IDENTIFIER INTEGER INTEGER_RATIONAL
    )

    def initialize(source)
      result = Prism.lex(source)
      raise SyntaxError unless result.errors.empty?

      @tokens = result.value
    end

    def minify
      minified_values = []
      heredoc_content_tokens = []
      squiggly_heredoc, in_heredoc = false
      prev_token, string_quote = nil

      @tokens.each_cons(2) do |(token, _lex_state), (next_token, _next_lex_state)|
        case token.type
        when :COMMENT
          if prev_token && prev_token.location.start_line == token.location.start_line && token.location.start_line < next_token.location.start_line
            minified_values << "\n"
          end
        when :IGNORED_NEWLINE, :EMBDOC_BEGIN, :EMBDOC_LINE, :EMBDOC_END
          # noop
        when :KEYWORD_END
          if NO_DELIMITER_VALUE_TYPES.include?(prev_token.type) && prev_token.location.start_line == token.location.start_line
            minified_values << ' '
          end
          minified_values << token.value
        when :HEREDOC_START
          in_heredoc = true
          squiggly_heredoc = token.value.start_with?('<<~')
          string_quote = if token.value.end_with?("'")
            "'"
          elsif token.value.end_with?('`')
            '`'
          else
            '"'
          end

          minified_values << string_quote
        when :STRING_CONTENT
          if in_heredoc
            heredoc_content_tokens << token
          else
            minified_values << token.value
          end
        when :HEREDOC_END
          heredoc_contents = if squiggly_heredoc
            minimum_indentation_length = heredoc_content_tokens.map { |token|
              token.value.match(/\A(?<indentation_spaces> *)/)[:indentation_spaces].length
            }.min

            indentation = ' ' * minimum_indentation_length

            heredoc_content_tokens.map { |token|
              token.value.delete_prefix!(indentation)
            }
          else
            heredoc_content_tokens.map(&:value)
          end

          minified_values << heredoc_contents << string_quote

          heredoc_content_tokens.clear
          in_heredoc = false
        when :NEWLINE
          minified_values << if next_token.type == :EOF
            token.value
          elsif next_token.type == :PARENTHESIS_RIGHT
            # noop
          else
            ';'
          end
        else
          minified_values << token.value
        end

        if padding_required?(token, next_token)
          minified_values << ' ' # Prevents syntax errros.
        end

        prev_token = token
      end

      minified_values.join
    end

    private

    def padding_required?(token, next_token)
      return true if token.type == :IDENTIFIER && (next_token.type == :IDENTIFIER || next_token.type == :CONSTANT)
      return false if next_token.type == :PARENTHESIS_LEFT

      AFTER_SPACE_REQUIRED_KEYWORDS.include?(token.type) || BEFORE_SPACE_REQUIRED_KEYWORDS.include?(next_token.type)
    end
  end
end
