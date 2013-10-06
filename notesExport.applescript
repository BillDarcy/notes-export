
-- for debugging
on outputDebugString(s)
	log s
	--display dialog s
end outputDebugString

-- get the path to which we should export this note
-- thisItem is a Notes Note or Folder
-- exportFolder is a Finder folder
on getNotePath(thisItem, exportFolder)
	tell application "Notes"
		my outputDebugString("+getNotePath " & name of thisItem)
		
		-- if thisItem is a folder, get the path to its containing folder
		set thisContainer to the container of thisItem
		if (the class of thisContainer) is folder then
			my outputDebugString("has parent " & (name of thisContainer) as text)
			
			set returnString to my getNotePath((container of thisItem), exportFolder)
			
			-- here, returnString will be the Notes folder path to thisItem
			my outputDebugString("getNotePath returned " & returnString)
			
			-- if thisItem is a folder, add its name to the returnString
			-- separated with a colon to build a Finder path 
			if (the class of thisItem) is folder then
				my outputDebugString((name of thisItem) & " is a folder")
				set returnString to returnString & ":" & name of thisItem
			end if
		else
			-- when thisItem is not a folder, 
			-- we ass/u/me its a top level note or folder.
			-- return its name to be added to the path.
			my outputDebugString("container of thisItem is not folder")
			set returnString to name of thisItem
		end if
	end tell
	
	return returnString
end getNotePath

-- write the contents of a note 
on writeToFile(pathToFolder, filename, filecontents)
	my outputDebugString("writeToFile:[" & pathToFolder & "], [" & filename & "]")
	
	-- -p makes the entire tree
	set makeDirectory to "mkdir -p " & quoted form of POSIX path of pathToFolder
	my outputDebugString(makeDirectory)
	do shell script makeDirectory
	
	set pathAndFile to (pathToFolder & ":" & filename)
	
	set the output to open for access file pathAndFile with write permission
	set eof of the output to 0
	write filecontents to the output starting at eof
	close access the output
end writeToFile

on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars

-- main function
-- choose a Finder Folder older to export the notes
-- append today's date to the Finder path so we can keep a daily export
-- export each note to a Finder Folder that mirrors its Notes Folder
tell application "Notes"
	activate
	display dialog "This is the export utility for Notes.app." & linefeed & linefeed & "Exactly " & (count of notes) & " notes are stored in the application. " & "Each one of them will be exported as a simple HTML file stored in a folder of your choice." with title "Notes Export" buttons {"Cancel", "Proceed"} cancel button "Cancel" default button "Proceed"
	set exportFolder to choose folder
	
	-- so we can keep daily copies of the exported notes,
	-- add a folder as "YYYMMDD" to the selected folder
	set {year:y, month:m, day:d} to (current date)
	set exportFolderWithDate to (exportFolder as string) & y & "-" & (m as integer) & "-" & d & ":"
	my outputDebugString(exportFolderWithDate)
	
	
	repeat with eachNote in every note
		-- get a Finder path to the note so we can export it there.
		set pathToNote to my getNotePath(eachNote, (exportFolder as string))
		
		my outputDebugString("path to note:" & pathToNote)
		
		set noteName to name of eachNote
		set noteBody to body of eachNote
		set noteName to my replace_chars(noteName, ":", "-")
		
		-- my outputDebugString("eachNote name:" & noteName)
		
		-- write the note to the folder made of:
		-- chosen Finder Folder : YYY-MM-DD : {Notes path to note} : Note name.html
		set pathToNote to (exportFolderWithDate & pathToNote)
		my writeToFile(pathToNote, noteName & ".html", noteBody as text)
	end repeat
	
	
	display alert "Notes Export" message "All notes were exported successfully." as informational
end tell
