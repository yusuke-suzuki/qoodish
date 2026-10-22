import { CardActions } from '@mui/material';
import type { ContentRef, Pin } from '../../../types/index.ts';
import CommentForm from '../common/CommentForm.tsx';
import LikePinButton from './LikePinButton.tsx';

type Props = {
  pin: Pin;
  onCommentAdded: () => void;
};

const PinCardActions = ({ pin, onCommentAdded }: Props) => {
  const subject: ContentRef = { type: 'pin', id: pin.id };

  const likeButton = <LikePinButton pin={pin} />;

  return (
    <CardActions sx={{ p: 2 }}>
      <CommentForm
        subject={subject}
        onCommentAdded={onCommentAdded}
        collapsedAction={likeButton}
      />
    </CardActions>
  );
};

export default PinCardActions;
