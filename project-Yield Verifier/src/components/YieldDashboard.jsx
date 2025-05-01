import React, { useState, useEffect } from 'react';
import { Card, CardContent, Grid, Typography, CircularProgress, Box } from '@mui/material';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { getContract } from '../contracts/config';

const YieldDashboard = ({ provider }) => {
  const [performanceData, setPerformanceData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPerformanceData = async () => {
      if (!provider) return;
      try {
        const dataFeed = getContract('DataFeed', provider);
        const currentTime = Math.floor(Date.now() / 1000);
        const startTime = currentTime - (30 * 24 * 60 * 60); // Last 30 days for better trend analysis
        
        const [events, latestYield] = await Promise.all([
          dataFeed.getDepositWithdrawalEvents(startTime, currentTime),
          dataFeed.getLatestYieldRate()
        ]);

        // Calculate daily yields
        const dailyData = events.map((event, index) => {
          const timestamp = new Date(startTime * 1000 + (index * 24 * 60 * 60 * 1000));
          return {
            timestamp: timestamp.toLocaleDateString(),
            score: Number(ethers.utils.formatUnits(event, 18)),
            date: timestamp
          };
        });

        // Add latest yield
        dailyData.push({
          timestamp: new Date().toLocaleDateString(),
          score: Number(ethers.utils.formatUnits(latestYield, 18)),
          date: new Date()
        });

        // Sort by date
        dailyData.sort((a, b) => a.date - b.date);
        
        setPerformanceData(dailyData);
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

  if (!performanceData || performanceData.length === 0) {
    return (
      <Card sx={{ mb: 4, background: 'rgba(255, 255, 255, 0.05)', backdropFilter: 'blur(10px)' }}>
        <CardContent>
          <Typography variant="h5" gutterBottom sx={{ color: '#fff' }}>
            No yield data available
          </Typography>
        </CardContent>
      </Card>
    );
  }

  const latestScore = performanceData[performanceData.length - 1].score;
  const averageScore = performanceData.reduce((acc, curr) => acc + curr.score, 0) / performanceData.length;
  const scoreChange = ((latestScore - performanceData[0].score) / performanceData[0].score * 100).toFixed(2);

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
                    formatter={(value) => [`${value.toFixed(4)}%`, 'Yield']}
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
                justifyContent: 'space-between',
                gap: 2
              }}
            >
              <Card sx={{ background: 'rgba(33, 150, 243, 0.1)' }}>
                <CardContent>
                  <Typography variant="h6" color="primary">
                    Current Yield
                  </Typography>
                  <Typography variant="h3" color="primary">
                    {latestScore.toFixed(4)}%
                  </Typography>
                  <Typography variant="body2" color={scoreChange >= 0 ? 'success.main' : 'error.main'}>
                    {scoreChange >= 0 ? '+' : ''}{scoreChange}% since start
                  </Typography>
                </CardContent>
              </Card>
              <Card sx={{ background: 'rgba(33, 150, 243, 0.1)' }}>
                <CardContent>
                  <Typography variant="h6" color="primary">
                    Average Yield
                  </Typography>
                  <Typography variant="h4" color="primary">
                    {averageScore.toFixed(4)}%
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