import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  CardActionArea,
  Avatar,
  Button,
  Chip,
  CircularProgress,
} from '@mui/material';
import {
  ArrowBack,
  Article,
  Lightbulb,
  Description,
  Assessment,
  Add,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { collection, getDocs, query, orderBy, limit } from 'firebase/firestore';
import { db } from '../../config/firebase';
import toast from 'react-hot-toast';

interface ExamHubStats {
  newsCount: number;
  tipsCount: number;
  papersCount: number;
  resultsCount: number;
}

const ExamHubPage: React.FC = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<ExamHubStats>({
    newsCount: 0,
    tipsCount: 0,
    papersCount: 0,
    resultsCount: 0,
  });

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      setLoading(true);
      
      // Get counts for each collection
      const [newsSnapshot, tipsSnapshot, papersSnapshot, resultsSnapshot] = await Promise.all([
        getDocs(collection(db, 'exam_hub_news')),
        getDocs(collection(db, 'exam_hub_tips')),
        getDocs(collection(db, 'exam_hub_papers')),
        getDocs(collection(db, 'exam_hub_results')),
      ]);

      setStats({
        newsCount: newsSnapshot.size,
        tipsCount: tipsSnapshot.size,
        papersCount: papersSnapshot.size,
        resultsCount: resultsSnapshot.size,
      });
    } catch (error) {
      console.error('Error loading exam hub stats:', error);
      toast.error('Failed to load exam hub statistics');
    } finally {
      setLoading(false);
    }
  };

  const examHubCards = [
    {
      title: 'News',
      description: 'Manage exam-related news and announcements',
      icon: <Article />,
      path: '/exam-hub/news',
      color: '#2196F3',
      count: stats.newsCount,
    },
    {
      title: 'Tips & Shortcuts',
      description: 'Share study tips and exam shortcuts',
      icon: <Lightbulb />,
      path: '/exam-hub/tips',
      color: '#FF9800',
      count: stats.tipsCount,
    },
    {
      title: 'Previous Year Papers',
      description: 'Upload and manage previous year question papers',
      icon: <Description />,
      path: '/exam-hub/papers',
      color: '#4CAF50',
      count: stats.papersCount,
    },
    {
      title: 'Results',
      description: 'Publish exam results and merit lists',
      icon: <Assessment />,
      path: '/exam-hub/results',
      color: '#9C27B0',
      count: stats.resultsCount,
    },
  ];

  const handleCardClick = (path: string) => {
    navigate(path);
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <Button
          variant="outlined"
          startIcon={<ArrowBack />}
          onClick={() => navigate('/dashboard')}
          sx={{ minWidth: 'auto' }}
        >
          Back to Dashboard
        </Button>
        <Typography variant="h4" component="h1">
          Exam Hub Management
        </Typography>
      </Box>

      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Manage exam-related content including news, tips, previous year papers, and results. 
        Upload PDF documents and create content that will be accessible to mobile app users.
      </Typography>

      {/* Statistics Overview */}
      <Card sx={{ mb: 4, background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}>
        <CardContent>
          <Typography variant="h6" sx={{ color: 'white', mb: 2 }}>
            Exam Hub Overview
          </Typography>
          <Grid container spacing={3}>
            {examHubCards.map((card, index) => (
              <Grid item xs={6} md={3} key={index}>
                <Box textAlign="center">
                  <Typography variant="h3" sx={{ color: 'white', fontWeight: 'bold' }}>
                    {card.count}
                  </Typography>
                  <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.8)' }}>
                    {card.title}
                  </Typography>
                </Box>
              </Grid>
            ))}
          </Grid>
        </CardContent>
      </Card>

      {/* Management Cards */}
      <Typography variant="h5" component="h2" gutterBottom sx={{ mb: 3 }}>
        Content Management
      </Typography>

      <Grid container spacing={3}>
        {examHubCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={6} lg={3} key={index}>
            <Card
              sx={{
                height: '100%',
                transition: 'all 0.3s ease-in-out',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: 4,
                },
              }}
            >
              <CardActionArea
                onClick={() => handleCardClick(card.path)}
                sx={{ height: '100%', p: 3 }}
              >
                <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
                  <Avatar
                    sx={{
                      bgcolor: card.color,
                      width: 64,
                      height: 64,
                      mb: 2,
                    }}
                  >
                    {card.icon}
                  </Avatar>
                  
                  <Typography variant="h6" component="h3" gutterBottom>
                    {card.title}
                  </Typography>
                  
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    {card.description}
                  </Typography>

                  <Chip
                    label={`${card.count} items`}
                    size="small"
                    sx={{
                      bgcolor: card.color,
                      color: 'white',
                      fontWeight: 'bold',
                    }}
                  />
                </Box>
              </CardActionArea>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Quick Actions */}
      <Box sx={{ mt: 4, textAlign: 'center' }}>
        <Typography variant="h6" gutterBottom>
          Quick Actions
        </Typography>
        <Box sx={{ display: 'flex', gap: 2, justifyContent: 'center', flexWrap: 'wrap' }}>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => navigate('/exam-hub/news')}
            sx={{ bgcolor: '#2196F3' }}
          >
            Add News
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => navigate('/exam-hub/tips')}
            sx={{ bgcolor: '#FF9800' }}
          >
            Add Tips
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => navigate('/exam-hub/papers')}
            sx={{ bgcolor: '#4CAF50' }}
          >
            Add Papers
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => navigate('/exam-hub/results')}
            sx={{ bgcolor: '#9C27B0' }}
          >
            Add Results
          </Button>
        </Box>
      </Box>
    </Box>
  );
};

export default ExamHubPage;
