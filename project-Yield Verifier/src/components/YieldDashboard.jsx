import React, { useState, useEffect } from 'react';
import { Card, CardContent, Grid, Typography, CircularProgress, Box } from '@mui/material';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const YieldDashboard = ({ provider }) => {
  const [performanceData, setPerformanceData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPerformanceData = async () => {
      if (!provider) return;
      try {
        // Simulated data for demonstration
        const data = [
          { timestamp: '01/01', score: 85 },
          { timestamp: '01/02', score: 88 },
          { timestamp: '01/03', score: 92 },
          { timestamp: '01/04', score: 90 },
          { timestamp: '01/05', score: 95 }
        ];
        setPerformanceData(data);
      } catch (error) {
        console.error('Error fetching performance data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchPerformanceData();
  }, [provider]);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="300px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Card sx={{ mb: 4, background: 'rgba(255, 255, 255, 0.05)', backdropFilter: 'blur(10px)' }}>
      <CardContent>
        <Typography variant="h5" gutterBottom sx={{ color: '#fff' }}>
          Yield Performance
        </Typography>
        <Grid container spacing={3}>
          <Grid item xs={12} md={8}>
            <Box sx={{ height: 300, width: '100%' }}>
              <ResponsiveContainer>
                <LineChart data={performanceData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
                  <XAxis dataKey="timestamp" stroke="#fff" />
                  <YAxis stroke="#fff" />
                  <Tooltip
                    contentStyle={{
                      background: 'rgba(0,0,0,0.8)',
                      border: 'none',
                      borderRadius: '4px',
                      color: '#fff'
                    }}
                  />
                  <Line
                    type="monotone"
                    dataKey="score"
                    stroke="#2196f3"
                    strokeWidth={2}
                    dot={{ fill: '#2196f3' }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </Box>
          </Grid>
          <Grid item xs={12} md={4}>
            <Box
              sx={{
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                gap: 2
              }}
            >
              <Card sx={{ background: 'rgba(33, 150, 243, 0.1)' }}>
                <CardContent>
                  <Typography variant="h6" color="primary">
                    Current Score
                  </Typography>
                  <Typography variant="h3" color="primary">
                    {performanceData[performanceData.length - 1].score}
                  </Typography>
                </CardContent>
              </Card>
              <Card sx={{ background: 'rgba(33, 150, 243, 0.1)' }}>
                <CardContent>
                  <Typography variant="h6" color="primary">
                    Average Score
                  </Typography>
                  <Typography variant="h3" color="primary">
                    {Math.round(
                      performanceData.reduce((acc, curr) => acc + curr.score, 0) /
                        performanceData.length
                    )}
                  </Typography>
                </CardContent>
              </Card>
            </Box>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );
};

export default YieldDashboard;