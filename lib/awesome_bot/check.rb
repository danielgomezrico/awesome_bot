require 'awesome_bot/links'
require 'awesome_bot/log'
require 'awesome_bot/result'
require 'awesome_bot/statuses'

# Check links
module AwesomeBot
  NUMBER_OF_THREADS = 10

  STATUS_OK = '✓'
  STATUS_OTHER = 'x'
  STATUS_REDIRECT = '→'  

  class << self
    def check(content, white_listed = nil, skip_dupe = false, log = Log.new)
      log.add '> Will allow duplicate links' if skip_dupe

      temp = links_filter(links_find(content))

      r = Result.new(temp, white_listed)
      r.skip_dupe = skip_dupe

      log.add "> White list: #{white_listed.join ', '}" if r.white_listing

      r.dupes = r.links.select { |e| r.links.count(e) > 1 } unless skip_dupe

      log.addp "Links found: #{r.links.count}"
      log.addp ", #{r.rejected.count} white listed" if r.white_listing
      unless skip_dupe
        log.addp ", #{r.links.uniq.count} unique" if r.dupes.count > 0
      end
      log.add ''
      r.links.uniq.each_with_index { |u, j| log.add "  #{j + 1}. #{u}" }

      log.addp 'Checking URLs: ' if r.links.count > 0
      r.status =
        statuses(r.links.uniq, NUMBER_OF_THREADS) do |s|
          if (s > 299) && (s < 400)
            log.addp STATUS_REDIRECT
          else
            log.addp(s == 200 ? STATUS_OK : STATUS_OTHER)
          end
        end
      log.add ''

      return r if !r.white_listing || (r.rejected.count == 0)

      log.addp 'Checking white listed URLs: '
      r.white_listed =
        statuses(r.rejected.uniq, NUMBER_OF_THREADS, true) do |s|
          if (s > 299) && (s < 400)
            log.addp STATUS_REDIRECT
          else
            log.addp(s == 200 ? STATUS_OK : STATUS_OTHER)
          end
        end
      log.add ''

      r
    end # check
  end # class
end
