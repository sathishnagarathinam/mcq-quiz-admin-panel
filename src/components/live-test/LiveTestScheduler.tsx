import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Switch,
  FormControlLabel,
  Chip,
  OutlinedInput,
  SelectChangeEvent,
  Alert,
} from '@mui/material';
import { DateTimePicker } from '@mui/x-date-pickers/DateTimePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';

export interface LiveTestData {
  title: string;
  description: string;
  startTime: Date;
  endTime: Date;
  durationMinutes: number;
  maxParticipants: number;
  instructorName: string;
  instructorImage: string;
  tags: string[];
  difficulty: 'easy' | 'medium' | 'hard';
  passingScore: number;
  showResults: boolean;
  isActive: boolean;
}

interface LiveTestSchedulerProps {
  examName: string;
  examType: string;
  suitableFor: string[];
  totalQuestions: number;
  enabled: boolean;
  onEnabledChange: (enabled: boolean) => void;
  onDataChange: (data: LiveTestData | null) => void;
}

const LiveTestScheduler: React.FC<LiveTestSchedulerProps> = ({
  examName,
  examType,
  suitableFor,
  totalQuestions,
  enabled,
  onEnabledChange,
  onDataChange,
}) => {
  const [liveTestData, setLiveTestData] = useState<LiveTestData>({
    title: `Live Test: ${examName}`,
    description: `Scheduled live test for ${examName} exam`,
    startTime: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
    endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000), // Tomorrow + 2 hours
    durationMinutes: 60,
    maxParticipants: 1000,
    instructorName: '',
    instructorImage: '',
    tags: [],
    difficulty: 'medium',
    passingScore: 60,
    showResults: true,
    isActive: true,
  });

  const difficultyOptions = [
    { value: 'easy', label: '🟢 Easy', color: 'success' },
    { value: 'medium', label: '🟡 Medium', color: 'warning' },
    { value: 'hard', label: '🔴 Hard', color: 'error' },
  ];

  const tagOptions = [
    'Practice Test', 'Mock Exam', 'Assessment', 'Competition', 
    'Weekly Test', 'Monthly Test', 'Final Exam', 'Revision'
  ];

  const handleDataChange = (newData: Partial<LiveTestData>) => {
    const updatedData = { ...liveTestData, ...newData };
    setLiveTestData(updatedData);
    
    if (enabled) {
      onDataChange(updatedData);
    }
  };

  const handleEnabledChange = (newEnabled: boolean) => {
    onEnabledChange(newEnabled);
    if (newEnabled) {
      // Update title and description when enabling
      const updatedData = {
        ...liveTestData,
        title: `Live Test: ${examName}`,
        description: `Scheduled live test for ${examName} exam`,
      };
      setLiveTestData(updatedData);
      onDataChange(updatedData);
    } else {
      onDataChange(null);
    }
  };

  const handleTagsChange = (event: SelectChangeEvent<string[]>) => {
    const value = event.target.value as string[];
    handleDataChange({ tags: value });
  };

  return (
    <Card sx={{ mt: 2 }}>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
          <Box display="flex" alignItems="center">
            <Typography variant="h6" sx={{ mr: 2 }}>
              📅 Schedule as Live Test
            </Typography>
            <FormControlLabel
              control={
                <Switch
                  checked={enabled}
                  onChange={(e) => handleEnabledChange(e.target.checked)}
                  color="primary"
                />
              }
              label={enabled ? "Enabled" : "Disabled"}
            />
          </Box>
        </Box>

        {enabled && (
          <Box>
            <Alert severity="info" sx={{ mb: 3 }}>
              <Typography variant="body2">
                This exam will be scheduled as a live test that all users can participate in at the specified time.
                The exam questions will be used for the live test.
              </Typography>
            </Alert>

            <Grid container spacing={3}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Live Test Title"
                  value={liveTestData.title}
                  onChange={(e) => handleDataChange({ title: e.target.value })}
                  helperText="This will be displayed to users"
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Difficulty Level</InputLabel>
                  <Select
                    value={liveTestData.difficulty}
                    label="Difficulty Level"
                    onChange={(e) => handleDataChange({ difficulty: e.target.value as 'easy' | 'medium' | 'hard' })}
                  >
                    {difficultyOptions.map((option) => (
                      <MenuItem key={option.value} value={option.value}>
                        {option.label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={2}
                  label="Description"
                  value={liveTestData.description}
                  onChange={(e) => handleDataChange({ description: e.target.value })}
                  helperText="Provide details about the live test"
                />
              </Grid>

              <LocalizationProvider dateAdapter={AdapterDateFns}>
                <Grid item xs={12} sm={6}>
                  <DateTimePicker
                    label="Start Time"
                    value={liveTestData.startTime}
                    onChange={(newValue) => newValue && handleDataChange({ startTime: newValue })}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        helperText: "When the live test begins"
                      }
                    }}
                  />
                </Grid>

                <Grid item xs={12} sm={6}>
                  <DateTimePicker
                    label="End Time"
                    value={liveTestData.endTime}
                    onChange={(newValue) => newValue && handleDataChange({ endTime: newValue })}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        helperText: "When the live test ends"
                      }
                    }}
                  />
                </Grid>
              </LocalizationProvider>

              <Grid item xs={12} sm={4}>
                <TextField
                  fullWidth
                  type="number"
                  label="Duration (minutes)"
                  value={liveTestData.durationMinutes}
                  onChange={(e) => handleDataChange({ durationMinutes: parseInt(e.target.value) || 60 })}
                  helperText="Time limit per participant"
                />
              </Grid>

              <Grid item xs={12} sm={4}>
                <TextField
                  fullWidth
                  type="number"
                  label="Max Participants"
                  value={liveTestData.maxParticipants}
                  onChange={(e) => handleDataChange({ maxParticipants: parseInt(e.target.value) || 1000 })}
                  helperText="Maximum number of participants"
                />
              </Grid>

              <Grid item xs={12} sm={4}>
                <TextField
                  fullWidth
                  type="number"
                  label="Passing Score (%)"
                  value={liveTestData.passingScore}
                  onChange={(e) => handleDataChange({ passingScore: parseInt(e.target.value) || 60 })}
                  helperText="Minimum score to pass"
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Instructor Name (Optional)"
                  value={liveTestData.instructorName}
                  onChange={(e) => handleDataChange({ instructorName: e.target.value })}
                  helperText="Name of the test conductor"
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Tags</InputLabel>
                  <Select
                    multiple
                    value={liveTestData.tags}
                    onChange={handleTagsChange}
                    input={<OutlinedInput label="Tags" />}
                    renderValue={(selected) => (
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {selected.map((value) => (
                          <Chip key={value} label={value} size="small" />
                        ))}
                      </Box>
                    )}
                  >
                    {tagOptions.map((tag) => (
                      <MenuItem key={tag} value={tag}>
                        {tag}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={liveTestData.showResults}
                      onChange={(e) => handleDataChange({ showResults: e.target.checked })}
                    />
                  }
                  label="Show results to participants after completion"
                />
              </Grid>
            </Grid>

            <Box mt={2}>
              <Typography variant="body2" color="text.secondary">
                <strong>Summary:</strong> Live test "{liveTestData.title}" will be scheduled from{' '}
                {liveTestData.startTime.toLocaleString()} to {liveTestData.endTime.toLocaleString()}{' '}
                with {totalQuestions} questions for {suitableFor.join(', ')} candidates.
              </Typography>
            </Box>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export default LiveTestScheduler;
