import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Grid,
  Card,
  CardContent,
  Alert,
  CircularProgress,
  Autocomplete,
  FormControlLabel,
  Switch,
  Divider,
} from '@mui/material';
import {
  Send as SendIcon,
  Image as ImageIcon,
  Schedule as ScheduleIcon,
  People as PeopleIcon,
  ArrowBack as ArrowBackIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { NotificationService } from '../../services/notificationService';
import { NotificationTarget, MobileUser } from '../../types/notification';
import { useAuth } from '../../contexts/AuthContext';

const NotificationSenderPage: React.FC = () => {
  const navigate = useNavigate();
  const { adminUser } = useAuth();
  
  // Form state
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [actionUrl, setActionUrl] = useState('');
  const [actionType, setActionType] = useState<'quiz' | 'exam' | 'news' | 'general' | 'test'>('general');
  const [priority, setPriority] = useState<'low' | 'normal' | 'high' | 'urgent'>('normal');
  const [category, setCategory] = useState<'announcement' | 'quiz_update' | 'exam_alert' | 'general' | 'system' | 'test_alert'>('general');
  const [testImageUrl, setTestImageUrl] = useState('');
  const [deliveryMethod, setDeliveryMethod] = useState<'push_only' | 'in_app_only' | 'both'>('both');
  
  // Target settings
  const [targetType, setTargetType] = useState<'all' | 'specific_users' | 'designation' | 'office'>('all');
  const [selectedUsers, setSelectedUsers] = useState<MobileUser[]>([]);
  const [selectedDesignation, setSelectedDesignation] = useState('');
  const [selectedOffice, setSelectedOffice] = useState('');
  
  // Scheduling
  const [isScheduled, setIsScheduled] = useState(false);
  const [scheduledDate, setScheduledDate] = useState('');
  const [scheduledTime, setScheduledTime] = useState('');
  
  // Data
  const [mobileUsers, setMobileUsers] = useState<MobileUser[]>([]);
  const [designations, setDesignations] = useState<string[]>([]);
  const [officeNames, setOfficeNames] = useState<string[]>([]);
  const [targetCount, setTargetCount] = useState(0);
  
  // Loading states
  const [loading, setLoading] = useState(false);
  const [dataLoading, setDataLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    calculateTargetCount();
  }, [targetType, selectedUsers, selectedDesignation, selectedOffice, mobileUsers]);

  const loadData = async () => {
    try {
      setDataLoading(true);
      const [users, designationsList, officesList] = await Promise.all([
        NotificationService.getMobileUsers(),
        NotificationService.getDesignations(),
        NotificationService.getOfficeNames(),
      ]);
      
      setMobileUsers(users);
      setDesignations(designationsList);
      setOfficeNames(officesList);
    } catch (error) {
      console.error('Error loading data:', error);
      toast.error('Failed to load user data');
    } finally {
      setDataLoading(false);
    }
  };

  const calculateTargetCount = async () => {
    try {
      const target: NotificationTarget = {
        type: targetType,
        userIds: selectedUsers.map(u => u.uid),
        designation: selectedDesignation,
        officeName: selectedOffice,
      };
      
      const targetUsers = await NotificationService.getTargetUsers(target);
      setTargetCount(targetUsers.length);
    } catch (error) {
      console.error('Error calculating target count:', error);
      setTargetCount(0);
    }
  };

  const isValidUrl = (url: string): boolean => {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  };

  const isValidImageUrl = (url: string): boolean => {
    if (!isValidUrl(url)) return false;

    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
    const urlLower = url.toLowerCase();

    // Check if URL ends with image extension or contains image-related patterns
    return imageExtensions.some(ext => urlLower.includes(ext)) ||
           urlLower.includes('image') ||
           urlLower.includes('img') ||
           urlLower.includes('photo') ||
           urlLower.includes('picture');
  };

  const handleSendNotification = async () => {
    if (!title.trim() || !body.trim()) {
      toast.error('Please fill in title and message');
      return;
    }

    // Validate image URLs if provided
    if (imageUrl.trim() && !isValidImageUrl(imageUrl.trim())) {
      toast.error('Please enter a valid image URL (jpg, png, gif, webp, svg)');
      return;
    }

    if (testImageUrl.trim() && !isValidImageUrl(testImageUrl.trim())) {
      toast.error('Please enter a valid test image URL (jpg, png, gif, webp, svg)');
      return;
    }

    // Validate action URL if provided
    if (actionUrl.trim() && !isValidUrl(actionUrl.trim())) {
      toast.error('Please enter a valid action URL');
      return;
    }

    if (!adminUser) {
      toast.error('Admin user not found');
      return;
    }

    try {
      setLoading(true);

      const target: NotificationTarget = {
        type: targetType,
        userIds: targetType === 'specific_users' ? selectedUsers.map(u => u.uid) : undefined,
        designation: targetType === 'designation' ? selectedDesignation : undefined,
        officeName: targetType === 'office' ? selectedOffice : undefined,
      };

      const content = {
        title: title.trim(),
        body: body.trim(),
        imageUrl: imageUrl.trim() !== '' ? imageUrl.trim() : undefined,
        actionUrl: actionUrl.trim() !== '' ? actionUrl.trim() : undefined,
        actionType: actionType !== 'general' ? actionType : undefined,
        testImageUrl: testImageUrl.trim() !== '' ? testImageUrl.trim() : undefined,
      };

      const scheduledFor = isScheduled && scheduledDate && scheduledTime
        ? new Date(`${scheduledDate}T${scheduledTime}`)
        : undefined;

      const notificationId = await NotificationService.createNotification(
        content,
        target,
        adminUser.uid,
        {
          priority,
          category,
          scheduledFor,
          deliveryMethod,
        }
      );

      if (!isScheduled) {
        await NotificationService.sendNotification(notificationId);
        toast.success('Notification sent successfully!');
      } else {
        toast.success('Notification scheduled successfully!');
      }

      // Reset form
      setTitle('');
      setBody('');
      setImageUrl('');
      setActionUrl('');
      setActionType('general');
      setTestImageUrl('');
      setPriority('normal');
      setCategory('general');
      setDeliveryMethod('both');
      setTargetType('all');
      setSelectedUsers([]);
      setSelectedDesignation('');
      setSelectedOffice('');
      setIsScheduled(false);
      setScheduledDate('');
      setScheduledTime('');

    } catch (error) {
      console.error('Error sending notification:', error);
      toast.error('Failed to send notification');
    } finally {
      setLoading(false);
    }
  };

  if (dataLoading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={() => navigate('/dashboard')}
          variant="outlined"
        >
          Back to Dashboard
        </Button>
        <Typography variant="h4" component="h1" sx={{ flexGrow: 1 }}>
          Send Notification
        </Typography>
      </Box>

      <Grid container spacing={3}>
        {/* Main Form */}
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Notification Content
            </Typography>

            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  required
                  placeholder="Enter notification title"
                />
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Message"
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  required
                  multiline
                  rows={4}
                  placeholder="Enter notification message"
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Image URL (Optional)"
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  placeholder="https://example.com/image.jpg"
                  InputProps={{
                    startAdornment: <ImageIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                  }}
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Action URL (Optional)"
                  value={actionUrl}
                  onChange={(e) => setActionUrl(e.target.value)}
                  placeholder="https://example.com/action"
                />
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Test Image URL (Optional)"
                  value={testImageUrl}
                  onChange={(e) => setTestImageUrl(e.target.value)}
                  placeholder="https://example.com/test-image.jpg"
                  helperText="For test-related notifications, provide an image link that will be displayed with the notification"
                  InputProps={{
                    startAdornment: <ImageIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                  }}
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Action Type</InputLabel>
                  <Select
                    value={actionType}
                    onChange={(e) => setActionType(e.target.value as any)}
                    label="Action Type"
                  >
                    <MenuItem value="general">General</MenuItem>
                    <MenuItem value="quiz">Quiz</MenuItem>
                    <MenuItem value="exam">Exam</MenuItem>
                    <MenuItem value="news">News</MenuItem>
                    <MenuItem value="test">Test</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Priority</InputLabel>
                  <Select
                    value={priority}
                    onChange={(e) => setPriority(e.target.value as any)}
                    label="Priority"
                  >
                    <MenuItem value="low">Low</MenuItem>
                    <MenuItem value="normal">Normal</MenuItem>
                    <MenuItem value="high">High</MenuItem>
                    <MenuItem value="urgent">Urgent</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Category</InputLabel>
                  <Select
                    value={category}
                    onChange={(e) => setCategory(e.target.value as any)}
                    label="Category"
                  >
                    <MenuItem value="general">General</MenuItem>
                    <MenuItem value="announcement">Announcement</MenuItem>
                    <MenuItem value="quiz_update">Quiz Update</MenuItem>
                    <MenuItem value="exam_alert">Exam Alert</MenuItem>
                    <MenuItem value="system">System</MenuItem>
                    <MenuItem value="test_alert">Test Alert</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Delivery Method</InputLabel>
                  <Select
                    value={deliveryMethod}
                    onChange={(e) => setDeliveryMethod(e.target.value as any)}
                    label="Delivery Method"
                  >
                    <MenuItem value="both">Push Notification + In-App</MenuItem>
                    <MenuItem value="push_only">Push Notification Only</MenuItem>
                    <MenuItem value="in_app_only">In-App Notification Only</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
            </Grid>

            <Divider sx={{ my: 3 }} />

            {/* Scheduling */}
            <Typography variant="h6" gutterBottom>
              Scheduling
            </Typography>

            <FormControlLabel
              control={
                <Switch
                  checked={isScheduled}
                  onChange={(e) => setIsScheduled(e.target.checked)}
                />
              }
              label="Schedule for later"
            />

            {isScheduled && (
              <Grid container spacing={2} sx={{ mt: 1 }}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    type="date"
                    label="Date"
                    value={scheduledDate}
                    onChange={(e) => setScheduledDate(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    type="time"
                    label="Time"
                    value={scheduledTime}
                    onChange={(e) => setScheduledTime(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                  />
                </Grid>
              </Grid>
            )}
          </Paper>
        </Grid>

        {/* Target Selection */}
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Target Audience
            </Typography>

            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Target Type</InputLabel>
              <Select
                value={targetType}
                onChange={(e) => setTargetType(e.target.value as any)}
                label="Target Type"
              >
                <MenuItem value="all">All Users</MenuItem>
                <MenuItem value="specific_users">Specific Users</MenuItem>
                <MenuItem value="designation">By Designation</MenuItem>
                <MenuItem value="office">By Office</MenuItem>
              </Select>
            </FormControl>

            {targetType === 'specific_users' && (
              <Autocomplete
                multiple
                options={mobileUsers}
                getOptionLabel={(option) => `${option.name} (${option.designation})`}
                value={selectedUsers}
                onChange={(_, newValue) => setSelectedUsers(newValue)}
                renderInput={(params) => (
                  <TextField {...params} label="Select Users" placeholder="Choose users" />
                )}
                renderTags={(value, getTagProps) =>
                  value.map((option, index) => (
                    <Chip
                      variant="outlined"
                      label={option.name}
                      {...getTagProps({ index })}
                      key={option.uid}
                    />
                  ))
                }
              />
            )}

            {targetType === 'designation' && (
              <FormControl fullWidth>
                <InputLabel>Designation</InputLabel>
                <Select
                  value={selectedDesignation}
                  onChange={(e) => setSelectedDesignation(e.target.value)}
                  label="Designation"
                >
                  {designations.map((designation) => (
                    <MenuItem key={designation} value={designation}>
                      {designation}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            )}

            {targetType === 'office' && (
              <FormControl fullWidth>
                <InputLabel>Office Name</InputLabel>
                <Select
                  value={selectedOffice}
                  onChange={(e) => setSelectedOffice(e.target.value)}
                  label="Office Name"
                >
                  {officeNames.map((office) => (
                    <MenuItem key={office} value={office}>
                      {office}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            )}

            {/* Target Count */}
            <Card sx={{ mt: 2, bgcolor: 'primary.50' }}>
              <CardContent sx={{ textAlign: 'center' }}>
                <PeopleIcon sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                <Typography variant="h4" color="primary.main">
                  {targetCount}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Users will receive this notification
                </Typography>
              </CardContent>
            </Card>

            {/* Send Button */}
            <Button
              fullWidth
              variant="contained"
              size="large"
              onClick={handleSendNotification}
              disabled={loading || targetCount === 0}
              startIcon={loading ? <CircularProgress size={20} /> : isScheduled ? <ScheduleIcon /> : <SendIcon />}
              sx={{ mt: 3 }}
            >
              {loading ? 'Processing...' : isScheduled ? 'Schedule Notification' : 'Send Notification'}
            </Button>

            {/* View History Button */}
            <Button
              fullWidth
              variant="outlined"
              onClick={() => navigate('/notifications')}
              sx={{ mt: 1 }}
            >
              View Notification History
            </Button>

            {targetCount === 0 && (
              <Alert severity="warning" sx={{ mt: 2 }}>
                No users match the selected criteria
              </Alert>
            )}
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default NotificationSenderPage;
