local Promise = require('pi.promise')
local config = require('pi.config')
local config_file = require('pi.config_file')
local model_picker = require('pi.model_picker')
local model_state = require('pi.model_state')

describe('pi.model_picker', function()
  local original_config
  local original_providers_promise
  local original_load

  before_each(function()
    original_config = vim.deepcopy(config.values)
    original_providers_promise = config_file.providers_promise
    original_load = model_state.load

    config.values = vim.deepcopy(config.defaults)
    config_file.providers_promise = Promise.new():resolve({
      providers = {
        {
          id = 'amazon-bedrock',
          name = 'Amazon Bedrock',
          models = {
            astra = { id = 'global.openai.gpt-6-astra', name = 'GPT-6 Astra' },
            regional = { id = 'openai.gpt-6-astra', name = 'GPT-6 Astra Regional' },
          },
        },
        {
          id = 'openai-codex',
          name = 'OpenAI Codex',
          models = {
            sol = { id = 'gpt-6.1-sol', name = 'GPT-6.1 Sol' },
          },
        },
      },
    })
    model_state.load = function()
      return { recent = {}, favorite = {}, variant = {} }
    end
  end)

  after_each(function()
    config.values = original_config
    config_file.providers_promise = original_providers_promise
    model_state.load = original_load
  end)

  it('shows only configured models when include is set', function()
    config.values.model_picker.include = {
      'amazon-bedrock/global.openai.gpt-6-astra',
      'openai-codex/gpt-6.1-sol',
    }

    local models = model_picker._get_models()

    assert.equal(2, #models)
    assert.same({
      'amazon-bedrock/global.openai.gpt-6-astra',
      'openai-codex/gpt-6.1-sol',
    }, vim.tbl_map(function(model)
      return model.provider .. '/' .. model.model
    end, models))
  end)

  it('shows every model when include is unset', function()
    local models = model_picker._get_models()

    assert.equal(3, #models)
  end)
end)
