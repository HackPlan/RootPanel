(if isPluginEnable('supervisor') then describe else describe.skip) 'plugin/supervisor', ->
  describe 'router', ->
    it 'POST update_program'

    it 'GET program_config'

    it 'POST program_control'

  describe 'programSummary', ->
    it 'pending'

  describe 'writeConfig', ->
    it 'pending'

  describe 'programStatus', ->
    it 'pending'

  describe 'updateProgram', ->
    it 'pending'

  describe 'programControl', ->
    it 'pending'

  describe 'removeConfig', ->
    it 'pending'

  describe 'removePrograms', ->
    it 'pending'
