#!/bin/bash

hidutil property --set '{"UserKeyMapping":
  [{"HIDKeyboardModifierMappingSrc":0x700000046,
    "HIDKeyboardModifierMappingDst":0x70000007F},
   {"HIDKeyboardModifierMappingSrc":0x700000047,
      "HIDKeyboardModifierMappingDst":0x700000081},
   {"HIDKeyboardModifierMappingSrc":0x700000048,
      "HIDKeyboardModifierMappingDst":0x700000080}]
}'
