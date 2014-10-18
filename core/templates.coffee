{fs, path} = app.libs

template_data = {}

for filename in fs.readdirSync "#{__dirname}/template"
  template_name = path.basename filename, path.extname(filename)
  template_data[template_name] = fs.readFileSync("#{__dirname}/template/#{filename}").toString()

module.exports = template_data
