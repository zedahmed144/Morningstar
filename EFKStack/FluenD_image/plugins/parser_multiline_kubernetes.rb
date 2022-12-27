
require 'fluent/plugin/parser_multiline'

module Fluent
  module Plugin
    class MultilineKubernetesParser < MultilineParser
      Fluent::Plugin.register_parser("multiline_kubernetes", self)

      CONF_FORMAT_FIRSTLINE = %q{/^\w\d{4}/}
      CONF_FORMAT1 = %q{/^(?<severity>\w)(?<time>\d{4} [^\s]*)\s+(?<pid>\d+)\s+(?<source>[^ \]]+)\] (?<message>.*)/}
      CONF_TIME_FORMAT = "%m%d %H:%M:%S.%N"

      def configure(conf)
        conf['format_firstline'] = CONF_FORMAT_FIRSTLINE
        conf['format1'] = CONF_FORMAT1
        conf['time_format'] = CONF_TIME_FORMAT
        super
      end
    end
  end
end
