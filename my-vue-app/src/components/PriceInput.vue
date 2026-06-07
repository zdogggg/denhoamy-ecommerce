<template>
  <el-input
    :model-value="displayText"
    :size="size"
    :disabled="disabled"
    :placeholder="placeholder"
    inputmode="numeric"
    autocomplete="off"
    @update:model-value="handleInput"
    @focus="focused = true"
    @blur="handleBlur"
  />
</template>

<script setup>
import { ref, watch } from 'vue'
import { formatPriceInput, parsePriceInput } from '../utils/format'

const props = defineProps({
  modelValue: { type: [Number, null], default: 0 },
  placeholder: { type: String, default: '0' },
  disabled: { type: Boolean, default: false },
  size: { type: String, default: 'default' },
  /** true: xóa hết → emit null (dùng cho trường không bắt buộc) */
  nullable: { type: Boolean, default: false }
})

const emit = defineEmits(['update:modelValue'])

const displayText = ref('')
const focused = ref(false)

const syncFromModel = () => {
  if (props.nullable && (props.modelValue === null || props.modelValue === undefined)) {
    displayText.value = ''
    return
  }
  const num = Number(props.modelValue) || 0
  displayText.value = num > 0 ? formatPriceInput(num) : ''
}

watch(() => props.modelValue, () => {
  if (!focused.value) syncFromModel()
}, { immediate: true })

const handleInput = (raw) => {
  const text = String(raw ?? '')
  const parsed = parsePriceInput(text)

  if (parsed === '') {
    displayText.value = text.replace(/\D/g, '')
    emit('update:modelValue', props.nullable ? null : 0)
    return
  }

  const num = Number(parsed)
  displayText.value = formatPriceInput(num)
  emit('update:modelValue', num)
}

const handleBlur = () => {
  focused.value = false
  syncFromModel()
}
</script>
