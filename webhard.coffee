URL = "http://server-url"

casper = require("casper").create()

getFiles = ->
	files = []
	rows = document.querySelectorAll('.tablecont')	
	for x in rows
		continue if x.children.length == 1

		files.push
			file : x.children[4].children[0].children[0].innerHTML
			size : x.children[5].innerHTML
			uploaded  : x.children[2].innerHTML
			seq : x.querySelector('[name=s_file_seq]').value		
	files

casper.Login = (userid,password) ->
	@then ->	
		@fill "form[name=LoginForm]", userid: userid, password: password, true

casper.ListFiles = ->
	@then ->
		files = @evaluate(getFiles)

		for file in files
			console.log JSON.stringify file	

casper.UploadFile = (file) ->
	@then ->
		@echo "uploading #{file}"

		@click '[name=Form1] p img'
		@click '[name=http_upload_yn]:nth-child(2)'
		@fill '[name=Form2]', http_file:file, true

casper.DeleteFile = (file) ->
	@then ->
		@echo "deleting #{file.file} [#{file.seq}]"

		confirmed = false
		@removeAllFilters	'page.confirm'
		@setFilter 'page.confirm', -> 
			confirmed = true
			true

		@evaluate (seq) ->
			fn_Delete(seq)
		, file.seq

		@waitFor (-> confirmed)

casper.DownloadFile = (file) ->
	@then ->
		@echo "downloading #{file.file} [#{file.seq}]"
		url = "#{URL}/filetran.SingleDownload.do?s_file_seq=#{file.seq}"
		@download url, "/Downloaded/#{file.file}"

casper.DeleteAllFiles = ->
	@then ->
		files = @evaluate(getFiles)

		@each files, (self, file) ->
			@DeleteFile file

casper.DownloadAllFiles = ->
	@then ->
		files = @evaluate(getFiles)

		@each files, (self, file) ->
			@DownloadFile file

casper.DDAllFiles = ->
	@then ->
		files = @evaluate(getFiles)

		@each files, (self, file) ->
			@DownloadFile file
			@DeleteFile file

[URL,userid,password,command,args...] = casper.cli.args

casper.start URL

casper.then ->
	@Login userid, password

	switch command
		when 'test'
			@UploadFile 'c:/Install.log'
			@ListFiles()
			@DownloadAllFiles()
			@DeleteAllFiles()
		when 'upload' then @UploadFile args[0]
		when 'list' then @ListFiles()
		when 'downloadall' then @DownloadAllFiles()
		when 'ddall' then @DDAllFiles()
		when 'deleteall' then @DeleteAllFiles()
		else
			@echo 'unknown command'

casper.run()
