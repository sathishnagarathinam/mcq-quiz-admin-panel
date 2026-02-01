/**
 * CSV Validation Utility
 * Provides comprehensive validation for CSV file uploads with detailed error reporting
 */

// Error severity levels
export type CSVErrorSeverity = 'error' | 'warning';

// Structure for a single CSV validation error
export interface CSVValidationError {
  row: number;           // 1-based row number (1 = header, 2+ = data rows)
  column: string | null; // Column name or null for row-level errors
  columnIndex: number | null; // 0-based column index
  field: string;         // Field/column name for display
  message: string;       // Human-readable error description
  severity: CSVErrorSeverity;
  value?: string;        // The problematic value (if applicable)
}

// Result of CSV validation
export interface CSVValidationResult<T> {
  isValid: boolean;
  errors: CSVValidationError[];
  warnings: CSVValidationError[];
  data: T[];
  totalRows: number;
  validRows: number;
  skippedRows: number;
}

// Column definition for validation
export interface CSVColumnDefinition {
  name: string;          // Expected column name
  aliases?: string[];    // Alternative names (e.g., 'option1', 'option_1')
  required: boolean;
  type: 'string' | 'number' | 'enum';
  enumValues?: string[]; // Valid values for enum type
  minLength?: number;
  maxLength?: number;
  minValue?: number;
  maxValue?: number;
  customValidator?: (value: string, rowIndex: number) => string | null; // Returns error message or null
}

// Schema definition for a CSV file type
export interface CSVSchema {
  columns: CSVColumnDefinition[];
  minRows?: number;
  maxRows?: number;
}

// Default schema for quiz/question CSV uploads
export const QUESTION_CSV_SCHEMA: CSVSchema = {
  columns: [
    {
      name: 'question',
      aliases: ['question text', 'question_text', 'questiontext'],
      required: true,
      type: 'string',
      minLength: 3,
      maxLength: 1000,
    },
    {
      name: 'option1',
      aliases: ['option_1', 'option 1', 'opt1', 'choice1', 'choice_1'],
      required: true,
      type: 'string',
      minLength: 1,
      maxLength: 500,
    },
    {
      name: 'option2',
      aliases: ['option_2', 'option 2', 'opt2', 'choice2', 'choice_2'],
      required: true,
      type: 'string',
      minLength: 1,
      maxLength: 500,
    },
    {
      name: 'option3',
      aliases: ['option_3', 'option 3', 'opt3', 'choice3', 'choice_3'],
      required: false,
      type: 'string',
      maxLength: 500,
    },
    {
      name: 'option4',
      aliases: ['option_4', 'option 4', 'opt4', 'choice4', 'choice_4'],
      required: false,
      type: 'string',
      maxLength: 500,
    },
    {
      name: 'correct',
      aliases: ['correct_answer', 'correctanswer', 'correct answer', 'answer'],
      required: true,
      type: 'number',
      minValue: 1,
      maxValue: 4,
    },
    {
      name: 'difficulty',
      aliases: ['difficulty_level', 'level'],
      required: false,
      type: 'enum',
      enumValues: ['easy', 'medium', 'hard'],
    },
    {
      name: 'explanation',
      aliases: ['explanation_text', 'answer_explanation', 'reason'],
      required: false,
      type: 'string',
      maxLength: 2000,
    },
  ],
  minRows: 1,
  maxRows: 1000,
};

/**
 * Parse a CSV line handling quoted fields with commas
 */
export function parseCSVLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;
  
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    const nextChar = line[i + 1];
    
    if (char === '"') {
      if (inQuotes && nextChar === '"') {
        // Escaped quote
        current += '"';
        i++; // Skip next quote
      } else {
        // Toggle quote state
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      result.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  
  // Don't forget the last field
  result.push(current.trim());

  return result;
}

/**
 * Find column index by name or aliases
 */
function findColumnIndex(headers: string[], columnDef: CSVColumnDefinition): number {
  const lowerHeaders = headers.map(h => h.toLowerCase().trim());

  // Check main name
  let index = lowerHeaders.indexOf(columnDef.name.toLowerCase());
  if (index !== -1) return index;

  // Check aliases
  if (columnDef.aliases) {
    for (const alias of columnDef.aliases) {
      index = lowerHeaders.findIndex(h => h.includes(alias.toLowerCase()) || alias.toLowerCase().includes(h));
      if (index !== -1) return index;
    }
  }

  return -1;
}

/**
 * Validate a single cell value against its column definition
 */
function validateCell(
  value: string,
  columnDef: CSVColumnDefinition,
  rowIndex: number,
  columnIndex: number
): CSVValidationError | null {
  const cleanValue = value.replace(/^"|"$/g, '').trim();

  // Check required fields
  if (columnDef.required && !cleanValue) {
    return {
      row: rowIndex + 1, // Convert to 1-based
      column: columnDef.name,
      columnIndex,
      field: columnDef.name,
      message: `Required field "${columnDef.name}" is empty`,
      severity: 'error',
      value: cleanValue,
    };
  }

  // Skip further validation if empty and not required
  if (!cleanValue) return null;

  // Type-specific validation
  switch (columnDef.type) {
    case 'number': {
      const num = parseInt(cleanValue, 10);
      if (isNaN(num)) {
        return {
          row: rowIndex + 1,
          column: columnDef.name,
          columnIndex,
          field: columnDef.name,
          message: `"${columnDef.name}" must be a valid number. Got: "${cleanValue}"`,
          severity: 'error',
          value: cleanValue,
        };
      }
      if (columnDef.minValue !== undefined && num < columnDef.minValue) {
        return {
          row: rowIndex + 1,
          column: columnDef.name,
          columnIndex,
          field: columnDef.name,
          message: `"${columnDef.name}" must be at least ${columnDef.minValue}. Got: ${num}`,
          severity: 'error',
          value: cleanValue,
        };
      }
      if (columnDef.maxValue !== undefined && num > columnDef.maxValue) {
        return {
          row: rowIndex + 1,
          column: columnDef.name,
          columnIndex,
          field: columnDef.name,
          message: `"${columnDef.name}" must be at most ${columnDef.maxValue}. Got: ${num}`,
          severity: 'error',
          value: cleanValue,
        };
      }
      break;
    }
    case 'enum': {
      if (columnDef.enumValues && !columnDef.enumValues.includes(cleanValue.toLowerCase())) {
        return {
          row: rowIndex + 1,
          column: columnDef.name,
          columnIndex,
          field: columnDef.name,
          message: `"${columnDef.name}" must be one of: ${columnDef.enumValues.join(', ')}. Got: "${cleanValue}"`,
          severity: 'error',
          value: cleanValue,
        };
      }
      break;
    }
    case 'string': {
      if (columnDef.minLength !== undefined && cleanValue.length < columnDef.minLength) {
        return {
          row: rowIndex + 1,
          column: columnDef.name,
          columnIndex,
          field: columnDef.name,
          message: `"${columnDef.name}" must be at least ${columnDef.minLength} characters. Got: ${cleanValue.length}`,
          severity: 'error',
          value: cleanValue,
        };
      }
      if (columnDef.maxLength !== undefined && cleanValue.length > columnDef.maxLength) {
        return {
          row: rowIndex + 1,
          column: columnDef.name,
          columnIndex,
          field: columnDef.name,
          message: `"${columnDef.name}" exceeds maximum length of ${columnDef.maxLength} characters. Got: ${cleanValue.length}`,
          severity: 'warning',
          value: cleanValue.substring(0, 50) + '...',
        };
      }
      break;
    }
  }

  // Custom validator
  if (columnDef.customValidator) {
    const customError = columnDef.customValidator(cleanValue, rowIndex);
    if (customError) {
      return {
        row: rowIndex + 1,
        column: columnDef.name,
        columnIndex,
        field: columnDef.name,
        message: customError,
        severity: 'error',
        value: cleanValue,
      };
    }
  }

  return null;
}

// Question interface for parsed data
export interface ParsedQuestion {
  id: string;
  question: string;
  options: string[];
  correctAnswer: number;
  explanation?: string;
  difficulty: 'Easy' | 'Medium' | 'Hard';
}

/**
 * Main CSV validation function for question uploads
 */
export function validateQuestionCSV(csvText: string): CSVValidationResult<ParsedQuestion> {
  const errors: CSVValidationError[] = [];
  const warnings: CSVValidationError[] = [];
  const data: ParsedQuestion[] = [];

  // Split into lines and filter empty ones
  const allLines = csvText.split(/\r?\n/);
  const lines = allLines.filter(line => line.trim());

  if (lines.length === 0) {
    errors.push({
      row: 0,
      column: null,
      columnIndex: null,
      field: 'file',
      message: 'CSV file is empty',
      severity: 'error',
    });
    return { isValid: false, errors, warnings, data, totalRows: 0, validRows: 0, skippedRows: 0 };
  }

  if (lines.length < 2) {
    errors.push({
      row: 1,
      column: null,
      columnIndex: null,
      field: 'file',
      message: 'CSV file must contain at least a header row and one data row',
      severity: 'error',
    });
    return { isValid: false, errors, warnings, data, totalRows: lines.length, validRows: 0, skippedRows: 0 };
  }

  // Parse header row
  const headers = parseCSVLine(lines[0]);
  const schema = QUESTION_CSV_SCHEMA;

  // Map columns to their indices
  const columnMap: Map<string, number> = new Map();
  const missingRequired: string[] = [];

  for (const columnDef of schema.columns) {
    const index = findColumnIndex(headers, columnDef);
    if (index !== -1) {
      columnMap.set(columnDef.name, index);
    } else if (columnDef.required) {
      missingRequired.push(columnDef.name);
    }
  }

  // Report missing required columns
  if (missingRequired.length > 0) {
    errors.push({
      row: 1,
      column: null,
      columnIndex: null,
      field: 'headers',
      message: `Missing required columns: ${missingRequired.join(', ')}. Found columns: ${headers.join(', ')}`,
      severity: 'error',
    });
    return { isValid: false, errors, warnings, data, totalRows: lines.length, validRows: 0, skippedRows: lines.length - 1 };
  }

  // Check for max rows limit
  const dataRowCount = lines.length - 1;
  if (schema.maxRows && dataRowCount > schema.maxRows) {
    warnings.push({
      row: schema.maxRows + 2,
      column: null,
      columnIndex: null,
      field: 'file',
      message: `CSV contains ${dataRowCount} data rows, which exceeds the recommended limit of ${schema.maxRows}. Only the first ${schema.maxRows} rows will be processed.`,
      severity: 'warning',
    });
  }

  // Validate each data row
  let skippedRows = 0;
  const rowsToProcess = schema.maxRows ? Math.min(dataRowCount, schema.maxRows) : dataRowCount;
  const seenQuestions = new Map<string, number>(); // For duplicate detection

  for (let i = 1; i <= rowsToProcess; i++) {
    const rowErrors: CSVValidationError[] = [];
    const values = parseCSVLine(lines[i]);
    const rowNumber = i + 1; // 1-based, accounting for header

    // Check if row has enough columns
    if (values.length < columnMap.size) {
      errors.push({
        row: rowNumber,
        column: null,
        columnIndex: null,
        field: 'row',
        message: `Row has ${values.length} columns, expected at least ${columnMap.size}. Possible issue: unescaped commas in data.`,
        severity: 'error',
      });
      skippedRows++;
      continue;
    }

    // Validate each column
    for (const columnDef of schema.columns) {
      const colIndex = columnMap.get(columnDef.name);
      if (colIndex === undefined) continue;

      const value = values[colIndex] || '';
      const cellError = validateCell(value, columnDef, rowNumber - 1, colIndex);

      if (cellError) {
        if (cellError.severity === 'error') {
          rowErrors.push(cellError);
        } else {
          warnings.push(cellError);
        }
      }
    }

    // If row has errors, add them and skip this row for data extraction
    if (rowErrors.length > 0) {
      errors.push(...rowErrors);
      skippedRows++;
      continue;
    }

    // Extract and build question object
    const questionText = (values[columnMap.get('question')!] || '').replace(/^"|"$/g, '').trim();
    const option1 = (values[columnMap.get('option1')!] || '').replace(/^"|"$/g, '').trim();
    const option2 = (values[columnMap.get('option2')!] || '').replace(/^"|"$/g, '').trim();
    const option3Idx = columnMap.get('option3');
    const option4Idx = columnMap.get('option4');
    const option3 = option3Idx !== undefined ? (values[option3Idx] || '').replace(/^"|"$/g, '').trim() : '';
    const option4 = option4Idx !== undefined ? (values[option4Idx] || '').replace(/^"|"$/g, '').trim() : '';

    const correctIdx = columnMap.get('correct')!;
    const correctValue = (values[correctIdx] || '').replace(/^"|"$/g, '').trim();
    const correctAnswer = Math.max(0, parseInt(correctValue, 10) - 1);

    const difficultyIdx = columnMap.get('difficulty');
    const difficultyValue = difficultyIdx !== undefined
      ? (values[difficultyIdx] || '').replace(/^"|"$/g, '').trim()
      : 'Medium';

    const explanationIdx = columnMap.get('explanation');
    const explanation = explanationIdx !== undefined
      ? (values[explanationIdx] || '').replace(/^"|"$/g, '').trim()
      : undefined;

    // Build options array
    const options = [option1, option2];
    if (option3) options.push(option3);
    if (option4) options.push(option4);

    // Check for duplicate questions
    const questionKey = questionText.toLowerCase().substring(0, 100);
    if (seenQuestions.has(questionKey)) {
      warnings.push({
        row: rowNumber,
        column: 'question',
        columnIndex: columnMap.get('question')!,
        field: 'question',
        message: `Possible duplicate question found. Similar question exists at row ${seenQuestions.get(questionKey)}`,
        severity: 'warning',
        value: questionText.substring(0, 50) + '...',
      });
    } else {
      seenQuestions.set(questionKey, rowNumber);
    }

    // Validate correct answer is within options range
    if (correctAnswer >= options.length) {
      errors.push({
        row: rowNumber,
        column: 'correct',
        columnIndex: correctIdx,
        field: 'correct',
        message: `Correct answer (${correctAnswer + 1}) is greater than number of options (${options.length})`,
        severity: 'error',
      });
      skippedRows++;
      continue;
    }

    // Add valid question
    const parsedQuestion: ParsedQuestion = {
      id: `bulk_${Date.now()}_${i}`,
      question: questionText,
      options,
      correctAnswer,
      difficulty: (difficultyValue.charAt(0).toUpperCase() + difficultyValue.slice(1).toLowerCase()) as 'Easy' | 'Medium' | 'Hard',
      explanation: explanation || undefined,
    };

    data.push(parsedQuestion);
  }

  return {
    isValid: errors.length === 0,
    errors,
    warnings,
    data,
    totalRows: lines.length - 1,
    validRows: data.length,
    skippedRows,
  };
}

/**
 * Format errors for display in a user-friendly way
 */
export function formatCSVErrors(result: CSVValidationResult<any>): string {
  const lines: string[] = [];

  if (result.errors.length > 0) {
    lines.push(`❌ Found ${result.errors.length} error(s):\n`);
    result.errors.forEach((err, index) => {
      const location = err.row > 0
        ? `Row ${err.row}${err.column ? `, Column "${err.column}"` : ''}`
        : 'File';
      lines.push(`${index + 1}. [${location}] ${err.message}`);
      if (err.value) {
        lines.push(`   Value: "${err.value}"`);
      }
    });
  }

  if (result.warnings.length > 0) {
    if (lines.length > 0) lines.push('');
    lines.push(`⚠️ Found ${result.warnings.length} warning(s):\n`);
    result.warnings.forEach((warn, index) => {
      const location = warn.row > 0
        ? `Row ${warn.row}${warn.column ? `, Column "${warn.column}"` : ''}`
        : 'File';
      lines.push(`${index + 1}. [${location}] ${warn.message}`);
    });
  }

  return lines.join('\n');
}

