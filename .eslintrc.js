module.exports = {
  extends: [
    'react-app',
    'react-app/jest'
  ],
  rules: {
    // Treat these as warnings instead of errors
    '@typescript-eslint/no-unused-vars': 'warn',
    'react-hooks/exhaustive-deps': 'warn',
    
    // Allow unused variables in development
    'no-unused-vars': 'warn',
    
    // Don't fail build on these issues
    '@typescript-eslint/no-explicit-any': 'warn',
    'prefer-const': 'warn',
    'no-console': 'warn'
  },
  overrides: [
    {
      files: ['**/*.ts', '**/*.tsx'],
      rules: {
        '@typescript-eslint/no-unused-vars': ['warn', { 
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_' 
        }]
      }
    }
  ]
};
