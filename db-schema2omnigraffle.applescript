(*
Copyright (c) 2008, Christian Mittendorf <christian.mittendorf@googlemail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this 
list ofconditions and the following disclaimer. Redistributions in binary form 
must reproduce the above copyright notice, this list of conditions and the 
following disclaimer in the documentation and/or other materials provided with 
the distribution. Neither the name of the <ORGANIZATION> nor the names of its 
contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

$Id: db-schema2omnigraffle.applescript 8 2009-06-04 15:18:07Z christian.mittendorf $

*)

property mysql_binary : null
property mysql_user : ""
property mysql_pass : ""

property mysql_host : "localhost"
property mysql_port : "3306"

property font_normal : "Helvetica"
property font_bold : "Helvetica-Bold"
property font_italic : "Helvetica-Oblique"

property box_width : 160.0
property box_height : 20.0

property with_shadows : false


if mysql_binary is equal to null then
	try
		set mysql_binary to (do shell script "/usr/bin/which mysql")
	on error
		display dialog "Cannot find the mysql executable on the command line." buttons {"Ok"} default button 1 with title "An error occured…" with icon caution
		return
	end try
end if

set mysql_host to (text returned of (display dialog "MySQL DB Host:" default answer mysql_host buttons {"OK"} default button 1))
set mysql_port to (text returned of (display dialog "MySQL DB Port:" default answer mysql_port buttons {"OK"} default button 1))

set mysql_user to (text returned of (display dialog "MySQL DB User:" default answer mysql_user buttons {"OK"} default button 1))
set mysql_pass to (text returned of (display dialog "Password:" default answer mysql_pass buttons {"OK"} default button 1 with hidden answer))

set dbList to getMySQLDatabaseList(mysql_user, mysql_pass)
if (count of items of dbList) is 0 then
	return
end if
set theDatabase to (choose from list dbList with prompt "Select a Database:" OK button name "Select")

if theDatabase is not false then
	set the_db to item 1 of theDatabase
	set tableList to getMySQLTableList(mysql_user, mysql_pass, the_db)
	
	if (count of items in tableList) > 0 then
		set all_tables to (choose from list tableList with prompt "Select Tables:" OK button name "Select" with multiple selections allowed)
		
		if (count of items in all_tables) > 0 then
			
			tell application "OmniGraffle Professional 5"
				set window_list to every window where id > 0
				if number of items of window_list > 0 then
					set the_document to document of front window
				else
					set the_document to make new document at end of documents
				end if
			end tell
			
			set draw_table_list to {}
			set draw_connections_list to {}
			
			repeat with i from 1 to number of items in all_tables
				set the_table to item i of all_tables
				set table_desc to getMySQLTableDescription(mysql_user, mysql_pass, the_db, the_table)
				set draw_table_list to draw_table_list & {{table:the_table, desc:table_desc}}
			end repeat
			
			repeat with i from 1 to number of items in draw_table_list
				set table_to_draw to item i of draw_table_list
				drawTableDescription(table of table_to_draw, desc of table_to_draw)
			end repeat
			
			repeat with i from 1 to number of items in draw_connections_list
				set connection_to_draw to item i of draw_connections_list
				drawTableConnection(connection_to_draw)
			end repeat
			
			drawTableConnections()
			
			tell application "OmniGraffle Professional 5"
				tell front document
					tell first canvas
						activate
						layout (a reference to every graphic)
					end tell
				end tell
			end tell
		else
			display dialog "No tables selected." buttons {"Ok"} default button 1
		end if
	else
		display dialog "No tables found in Database \"" & theDatabase & "\"." buttons {"Ok"} default button 1
	end if
end if


on drawTableConnections()
	tell application "OmniGraffle Professional 5"
		tell front document
			tell first canvas
				set title_graphics to {}
				set entry_graphics to {}
				
				set all_groups to every group
				repeat with x from 1 to number of items in all_groups
					set graphics_list to graphics of item x of all_groups
					repeat with i from 1 to number of items in graphics_list
						set this_graphic to item i of graphics_list
						if i is 1 then
							set title_graphics to title_graphics & {this_graphic}
						else
							if text of this_graphic contains "_id" then
								set entry_graphics to entry_graphics & {this_graphic}
							end if
						end if
					end repeat
				end repeat
				
				repeat with i from 1 to number of items in title_graphics
					set this_title to item i of title_graphics
					
					set title_text to text of this_title
					if title_text ends with "ies" then
						set title_text to texts 1 thru ((number of characters of title_text) - 3) of title_text & "y"
					else if title_text ends with "s" then
						set title_text to texts 1 thru ((number of characters of title_text) - 1) of title_text
					end if
					
					repeat with i from 1 to number of items in entry_graphics
						set this_item to item i of entry_graphics
						
						if text of this_item begins with (title_text & "_id") then
							
							set my_line to make new line at end of graphics with properties {head type:"FilledArrow", tail type:"FilledBall", line type:orthogonal, point list:{{100, 100}, {200, 200}}}
							
							tell my_line
								set source to this_item
								set tail magnet to 1
								set destination to this_title
								set head magnet to 2
							end tell
							
						end if
					end repeat
					
				end repeat
				
			end tell
		end tell
	end tell
end drawTableConnections


on drawTableDescription(table_name, table_description)
	tell application "OmniGraffle Professional 5"
		activate
		tell front document
			
			set canvas_size to canvasSize of first canvas
			
			set page_height to item 1 of canvas_size
			set page_width to item 2 of canvas_size
			
			set page_y to page_height * 0.7
			set page_x to page_height * 0.3
			
			set max_width to 0
			set max_height to 0
			
			tell first canvas
				
				repeat with i from number of items in table_description to 1 by -1
					set the_row to item i of table_description
					
					if |Key| of the_row is equal to "PRI" then
						set theFont to font_bold
					else
						set theFont to font_normal
					end if
					
					if |Key| of the_row is equal to "MUL" then
						set the_text to {{font:font_italic, text:|Field| of the_row}, {font:theFont, text:" : " & |Type| of the_row}}
					else
						set field_name to get |Field| of the_row & " : " & |Type| of the_row
						set the_text to {font:theFont, text:field_name}
					end if
					
					set new_shape to make new shape at beginning of graphics with properties {magnets:{{1, 0}, {-1, 0}}, text:the_text, draws shadow:with_shadows, origin:{page_x, page_y}, thickness:0.5, size:{box_width, box_height}, autosizing:full}
					
					set tmp_size to size of new_shape
					set tmp_width to item 1 of tmp_size
					if tmp_width > max_width then
						set max_width to tmp_width
					end
					
					if max_height is 0 then
						set max_height to item 2 of tmp_size
						set box_height to max_height
					end
					
					set page_y to page_y - box_height
				end repeat
				
				set new_shape to make new shape at beginning of graphics with properties {magnets:{{0, 1}, {0, -1}}, text:{font:font_bold, alignment:center, text:table_name}, fill color:{0.8, 0.8, 0.8}, draws shadow:with_shadows, origin:{page_x, page_y}, thickness:0.5, size:{box_width, box_height}, autosizing:full}
				
				set tmp_size to size of new_shape
				set tmp_width to item 1 of tmp_size
				if tmp_width > max_width then
					set max_width to tmp_width
				end
				
				set page_y to page_y - box_height
				
				set theshapes to a reference to shapes 1 thru ((count of items in table_description) + 1)
				
				repeat with tmp_shape in theshapes
					set tmp_size to size of tmp_shape
					set item 1 of tmp_size to max_width
					set size of tmp_shape to tmp_size
				end repeat
				
				assemble theshapes
			end tell
		end tell
	end tell
end drawTableDescription

(* do a "show databases" and return a list of available databases *)
on getMySQLDatabaseList(user, pass)
	set dbList to {}
	
	set p to " "
	if pass is not "" then
		set p to " --password='" & pass & "' "
	end if
	
	try
		set mysql_result to do shell script mysql_binary & " -h " & mysql_host & " --silent -u " & user & p & "  -e 'show databases'" with altering line endings
		repeat with i from 1 to number of paragraphs in mysql_result
			set mysql_row to paragraph i of mysql_result
			set dbList to dbList & mysql_row
		end repeat
	on error e
		display dialog e buttons {"Ok"} default button 1 with title "An error occured…" with icon caution
	end try
	
	return dbList
end getMySQLDatabaseList

(* do a "show tables" and return a list of available tables*)
on getMySQLTableList(user, pass, dbname)
	set tableList to {}
	
	set p to " "
	if pass is not "" then
		set p to " --password='" & pass & "' "
	end if
	
	set mysql_result to do shell script mysql_binary & " -h " & mysql_host & " --silent -u " & user & p & dbname & " -e 'show tables'" with altering line endings
	
	repeat with i from 1 to number of paragraphs in mysql_result
		set mysql_row to paragraph i of mysql_result
		set tableList to tableList & mysql_row
	end repeat
	
	return tableList
end getMySQLTableList

(* do a "describe <table>" and return a hashmap with the table description *)
on getMySQLTableDescription(user, pass, dbname, table)
	set tableDescription to {}
	
	set p to " "
	if pass is not "" then
		set p to " --password='" & pass & "' "
	end if
	
	set mysql_result to do shell script mysql_binary & " -h " & mysql_host & " --silent -u " & user & p & dbname & " -e 'describe " & table & "'" with altering line endings
	
	set defaultTextDelimiters to text item delimiters
	set text item delimiters to tab
	
	set item_count to number of paragraphs in mysql_result
	repeat with i from 1 to item_count
		set rowDescription to {|Field|:"", |Type|:"", |NULL|:"", |Key|:"", |DefaultExtra|:""}
		
		set mysql_row to paragraph i of mysql_result
		
		set |Field| of rowDescription to text item 1 of mysql_row
		set |Type| of rowDescription to text item 2 of mysql_row
		set |NULL| of rowDescription to text item 3 of mysql_row
		set |Key| of rowDescription to text item 4 of mysql_row
		set |DefaultExtra| of rowDescription to text item 5 of mysql_row
		
		set tableDescription to tableDescription & {rowDescription}
	end repeat
	
	set text item delimiters to defaultTextDelimiters
	
	return tableDescription
end getMySQLTableDescription
