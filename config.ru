# encoding: utf-8

# Run with: rackup -s thin
# then browse to http://localhost:9292
# Or with: thin start -R config.ru
# then browse to http://localhost:3000
#
# Check Rack::Builder doc for more details on this file format:
# http://rack.rubyforge.org/doc/classes/Rack/Builder.html

require "pp"
require "date"
require "time"
require "sqlite3"
require "net/http"
require "cgi"

MAX_NICK = 30
MAX_COMMENT = 200

MEET_AT = IO.read("meet_at") rescue %(We’re not yet sure where to meet yet. Maybe you can find more in the <a href="https://www.noname-ev.de/w/Template:Aktuelles">upcoming events table</a>, otherwise please check back in a few days.)

CSS = IO.read("style.css").gsub(/\s+/, " ")

DB_FILE = File.dirname(__FILE__) + "/yarpdb.sqlite3"

HTML_HEADER = %(<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>YarpNarp</title>
    <style type="text/css">#{CSS}</style>
 </head>
 <body>
 <h1>YarpNarp</h1>
 <p>#{MEET_AT}</p>
 )

HTML_FOOTER = %(</body></html>)

def clean(text, length)
  (CGI::escapeHTML(text.gsub(/\s+/, " ").strip[0..length])) rescue nil
end

def render_row(row, nick)
  hlt = nick == row["nick"] ? %(class="highlight") : ""

  out = ""
  out << %(<tr #{hlt}>)
  out << %(<td>#{row["nick"]}</td>)
  out << %(<td title="#{row["comment"]}">#{row["comment"]}</td>)
  out << %(</tr>)
  out
end

def stat(nick)
  ($db.execute("SELECT yarp FROM yarpnarp WHERE nick = ?", nick)[0]["yarp"]) rescue -1
end

`touch "#{DB_FILE}"` unless File.exist?(DB_FILE)
$db = SQLite3::Database.new(DB_FILE)
$db.results_as_hash = true
$db.execute("CREATE TABLE yarpnarp(nick TEXT PRIMARY KEY, yarp BOOLEAN, comment TEXT)") rescue nil

app = proc do |env|
  out = []
  error = ""
  headers = { "Content-Type" => "text/html" }

  req = Rack::Request.new(env)
  p = req.params

  nick = clean p["nick"], MAX_NICK
  nick ||= clean req.cookies['nick'], MAX_NICK
  nick ||= ""

  comment = clean p["comment"], MAX_COMMENT
  comment ||= clean req.cookies['comment'], MAX_COMMENT
  comment ||= ""

  if ["yarp", "narp"].include?(p["action"])
    if nick.empty?
      error << "Missing a nick. What about “Robert'); DROP TABLE yarpnarp;--”?"
    else
      Rack::Utils.set_cookie_header!(headers, "nick", {:value => nick, :path => "/", :expires => Time.now+365*24*60*60})
      Rack::Utils.set_cookie_header!(headers, "comment", {:value => comment, :path => "/", :expires => Time.now+365*24*60*60})

      my_stat = p["action"] == "yarp" ? 1 : 0
      $db.execute2("INSERT OR REPLACE INTO yarpnarp(nick, yarp, comment) VALUES (?, ?, ?)", nick, my_stat, comment)

      if stat(nick) != my_stat
        error << "Your yarp/narp could not be saved. Server error maybe?"
      else
        begin
          next [ 302, headers.merge({ "Content-Type" => "text/html", "Location" => "http://" + req.env['HTTP_HOST'] }), ["How did you get here?"] ]
        rescue; end
      end
    end
  end



  if p["action"] == "SUPER_SECRET_CHANGE_ME" # php military security. keywords: reset clear clean
    $db.execute("DELETE FROM yarpnarp")
  end

  cnt_yarp = ($db.execute("SELECT COUNT(*) cnt FROM yarpnarp WHERE yarp = 1")[0]["cnt"]) rescue 0
  cnt_narp = ($db.execute("SELECT COUNT(*) cnt FROM yarpnarp WHERE yarp = 0")[0]["cnt"]) rescue 0


  out << HTML_HEADER
  out << %(<p class="error">#{error}</p>) unless error.empty?

  my_stat = stat(nick)
  iam = my_stat == 1 ? "yarp" : "narp"
  out << %(<p class="#{iam}"><b>Your Status:</b> #{iam}) if my_stat != -1

  out << %(<form>)
  out << %(<input type="text" name="nick" id="nick" value="#{nick}" maxlength="#{MAX_NICK}" placeholder="Nick"/>)
  out << %(<input type="text" name="comment" value="#{comment}" placeholder="Comment (Optional)" maxlength="200"/>)
  out << %(<input type="submit" name="action" value="yarp"/>)
  out << %(<input type="submit" name="action" value="narp"/>)
  out << %(</form>)

  out << %(<table>)
  out << %(<tr><th>Yarp</th><td>#{cnt_yarp} humans</td></tr>)
  $db.execute("SELECT * FROM yarpnarp WHERE yarp = 1 ORDER BY nick COLLATE NOCASE ASC") do |row|
    out << render_row(row, nick)
  end
  out << %(</table><table>)
  out << %(<tr><th>Narp</th><td>#{cnt_narp} humans</td></tr>)
  $db.execute("SELECT * FROM yarpnarp WHERE yarp = 0 ORDER BY nick COLLATE NOCASE ASC") do |row|
    out << render_row(row, nick)
  end
  out << %(</table>)

  out << %(<h3>Automatization</h3>)
  out << %(<p>You can automate yarp/narping, if you want to. The general URL format is shown below. Comment is always optional; nick only if your browser stored it as cookie once. If all goes well, it will report a 302 (redirect) or 200 (success). If it fails, it will report 418 (I’m a teapot).<br/>)
  out << %(<span>http://#{req.env['HTTP_HOST']}?action=<b>yarp</b>&amp;nick=<b>X</b>&amp;comment=<b>Y</b></span><br/>)
  out << %(<span>http://#{req.env['HTTP_HOST']}?action=<b>narp</b>&amp;nick=<b>X</b>&amp;comment=<b>Y</b></span><br/>)
  out << %(</p>)


  out << HTML_FOOTER
  [ error.empty? ? 200 : 418, headers, out ]
end

run app
