module Diffy
  class AdvancedHtmlFormatter < HtmlFormatter

    private
    def wrap_line(line)
      cleaned = clean_line(line)
      case line
        when /^(---|\+\+\+|\\\\)/
          '    <tr class="diff-comment"><td colspan="3">' + line.chomp + '</td></tr>'
        when /^\+/
          '    <tr class="ins"><ins>' + cleaned + '</ins></li>'
        when /^-/
          '    <tr class="del"><del>' + cleaned + '</del></tr>'
        when /^ /
          '    <tr class="unchanged"><span>' + cleaned + '</span></tr>'
        when /^@@/
          '    <tr class="diff-block-info"><span>' + line.chomp + '</span></li>'
      end
    end

    # remove +/- or wrap in html
    def clean_line(line)
      if @options[:include_plus_and_minus_in_html]
        line.sub(/^(.)/, '<span class="symbol">\1</span>')
      else
        line.sub(/^./, '')
      end.chomp
    end

    def wrap_lines(lines)
      if lines.empty?
        %'<div class="diff"/>'
      else
        %'<div class="diff">\n  <table>\n#{lines.join("\n")}\n  </table>\n</div>\n'
      end
    end

    def highlighted_words
      chunks = @diff.each_chunk.
          reject{|c| c == '\ No newline at end of file'"\n"}

      processed = []
      lines = chunks.each_with_index.map do |chunk1, index|
        next if processed.include? index
        processed << index
        chunk1 = chunk1
        chunk2 = chunks[index + 1]
        if not chunk2
          next ERB::Util.h(chunk1)
        end

        dir1 = chunk1.each_char.first
        dir2 = chunk2.each_char.first
        case [dir1, dir2]
          when ['-', '+']
            if chunk1.each_char.take(3).join("") =~ /^(---|\+\+\+|\\\\)/ and
                chunk2.each_char.take(3).join("") =~ /^(---|\+\+\+|\\\\)/
              ERB::Util.h(chunk1)
            else
              line_diff = Diffy::Diff.new(
                  split_characters(chunk1),
                  split_characters(chunk2)
              )
              hi1 = reconstruct_characters(line_diff, '-')
              hi2 = reconstruct_characters(line_diff, '+')
              processed << (index + 1)
              [hi1, hi2]
            end
          else
            ERB::Util.h(chunk1)
        end
      end.flatten
      lines.map{|line| line.each_line.map(&:chomp).to_a if line }.flatten.compact.
          map{|line|wrap_line(line) }.compact
    end




  end
end
