require 'fluent/plugin/parser_regexp'

module Fluent
  module Plugin
    class KubernetesParser < RegexpParser
      Fluent::Plugin.register_parser("kubernetes", self)

      CONF_FORMAT_FIRSTLINE = %q{/^\w\d{4}/}
      CONF_FORMAT1 = %q{/^(?<severity>\w)(?<time>\d{4} [^\s]*)\s+(?<pid>\d+)\s+(?<source>[^ \]]+)\] (?<message>.*)/m}
      CONF_TIME_FORMAT = "%m%d %H:%M:%S.%N"

      def configure(conf)
        conf['expression'] = CONF_FORMAT1
        conf['time_format'] = CONF_TIME_FORMAT
        super
      end
    end
  end
end
